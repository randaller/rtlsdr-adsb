program rtl_asyncread_adsb;

{$APPTYPE CONSOLE}

uses
  RtlSDR, TypInfo, Winapi.Windows, Winapi.Messages, System.SysUtils, Math;

const
  DEFAULT_BUF_LENGTH = 16 * 16384;

  preamble_len = 16;
  long_frame = 112;
  short_frame = 56;

var
  r: integer;
  dev: Pointer;

  thread_buf, buf: array [0 .. DEFAULT_BUF_LENGTH] of Byte;

  StopReadingSamples: Boolean = False;

  ThreadHandle: integer;
  ThreadID: DWORD;
  hSem: THandle = 0;

  adsb_frame: array [0 .. 13] of Byte;
  pyth: array [0 .. 128, 0 .. 128] of Byte;
  allowed_errors: integer = 5;
  quality: double = 1.0;
  short_output: integer = 0;
  verbose_output: integer = 1;

procedure Log(S: String);
begin
  writeln(S);
end;

procedure DLog(i: integer);
begin
  writeln(IntToStr(i));
end;

procedure FLog(F: double);
begin
  writeln(FloatToStr(F));
end;

procedure BufLog(buf: array of Byte; n_read: integer);
var
  S: String;
  i: integer;
begin
  S := '';
  for i := 0 to n_read do
    S := S + chr(buf[i]);
  write(S);
end;

function Read(buffer: PAnsiChar; size: integer; ctx: Pointer): LongWord;
begin
  if ctx = nil then
    Exit(0);

  // 262144 bytes in buffer = 128 kbytes I|Q data  *  8 bit  *  2 IQ channels
  // 128k * 8 bit = 1024k * 2 = 2048000 MSPS

  // writeln('read: ' + IntToStr(size) + ' bytes');

  // Move(buf, ctx, size);
  CopyMemory(@buf[0], ctx, size);

  hSem := CreateSemaphore(nil, 1, 1, nil);
  Result := 1;
end;

procedure pyth_precompute;
var
  x, y: integer;
  scale: double;
begin
  // use the full 8 bits
  scale := 1.408;

  for x := 0 to 128 do
    for y := 0 to 128 do
      pyth[x, y] := Byte(round(scale * sqrt(x * x + y * y)));
end;

function abs8(x: Byte): Byte; inline;
begin
  if (x >= 128) then
    Exit(x - 128);
  Result := 128 - x;
end;

function magnitute(var buf: array of Byte; len: integer): integer;
var
  i: integer;
begin
  i := 0;
  while (i < len) do
  begin
    buf[i div 2] := pyth[abs8(buf[i]), abs8(buf[i + 1])];
    Inc(i, 2);
  end;

  Result := len div 2;
end;

function single_manchester(a, b, c, d: integer): integer; inline;
var
  bit, bit_p: integer;
begin
  bit_p := ifthen(a > b, 1, 0);
  bit := ifthen(c > d, 1, 0);

  if quality = 0.0 then
    Exit(bit);

  if quality = 0.5 then
  begin
    if ((bit = 1) and (bit_p = 1) and (b > c)) then
      Exit(255);

    if ((bit = 0) and (bit_p = 0) and (b < c)) then
      Exit(255);

    Exit(bit);
  end;

  if quality = 1.0 then
  begin
    if ((bit = 1) and (bit_p = 1) and (c > b)) then
      Exit(1);

    if ((bit = 1) and (bit_p = 0) and (d < b)) then
      Exit(1);

    if ((bit = 0) and (bit_p = 1) and (d > b)) then
      Exit(0);

    if ((bit = 0) and (bit_p = 0) and (c < b)) then
      Exit(0);

    Exit(255);
  end;

  if ((bit = 1) and (bit_p = 1) and (c > b) and (d < a)) then
    Exit(1);

  if ((bit = 1) and (bit_p = 0) and (c > a) and (d < b)) then
    Exit(1);

  if ((bit = 0) and (bit_p = 1) and (c < a) and (d > b)) then
    Exit(0);

  if ((bit = 0) and (bit_p = 0) and (c < b) and (d > a)) then
    Exit(0);

  Result := 255;
end;

function preamble(var buf: array of Byte; len, i: integer): integer;
var
  i2: integer;
  low, high: Byte;
begin
  low := 0;
  high := 255;
  for i2 := 0 to preamble_len - 1 do
  begin
    case i2 of
      0, 2, 7, 9:
        high := buf[i + i2];
    else
      low := buf[i + i2];
    end;

    if high <= low then
      Exit(0);
  end;

  Result := 1;
end;

procedure manchester(var buf: array of Byte; len: integer);
var
  a, b, bit: Byte;
  i, i2, errors: integer;
begin
  a := 0;
  b := 0;
  i := 0;
  while (i < len) do
  begin
    // find preamble
    while i < (len - preamble_len) do
    begin
      if preamble(buf, len, i) = 0 then
      begin
        Inc(i);
        continue;
      end;
      a := buf[i];
      b := buf[i + 1];
      for i2 := 0 to preamble_len - 1 do
        buf[i + i2] := 253;
      Inc(i, preamble_len);
      break;

      Inc(i);
    end;

    i2 := i;
    errors := 0;

    // mark bits until encoding breaks
    while (i < len) do
    begin
      bit := single_manchester(a, b, buf[i], buf[i + 1]);
      a := buf[i];
      b := buf[i + 1];
      if bit = 255 then
      begin
        Inc(errors);
        if (errors > allowed_errors) then
        begin
          buf[i2] := 255;
          break;
        end
        else
        begin
          bit := ifthen(a > b, 1, 0);
          a := 0;
          b := 255;
        end;

      end;
      buf[i] := 254;
      buf[i + 1] := 254;
      buf[i2] := bit;

      Inc(i, 2);
      Inc(i2);
    end;

  end;
end;

procedure display(var frame: array of Byte; len: integer);
var
  i, df: integer;
begin
  if (short_output = 0) and (len <= short_frame) then
    Exit;

  df := (frame[0] shr 3) and $1F;

  if (quality = 0.0) and not((df = 11) or (df = 17) or (df = 18) or (df = 19))
  then
    Exit;

  write('*');
  for i := 0 to ((len + 7) div 8) - 1 do
    write(format('%.2x', [frame[i]]));
  writeln(';');

  if (verbose_output = 1) then
  begin
    writeln(' ' + formatdatetime('dd-mm-yyyy hh:nn:ss.zzz', Now));
    write(format(' DF=%d, CA=%d', [df, frame[0] and $07]));
    write(format(', ICAO=%.6x', [(frame[1] shl 16) or (frame[2] shl 8) or
      frame[3]]));
    writeln;
  end;

  if len <= short_frame then
    Exit;

  if (verbose_output = 1) then
  begin
    writeln(format(' PI=0x%.6x', [(frame[11] shl 16) or (frame[12] shl 8) or
      frame[13]]));

    writeln(format(' type_code=%d, s_type/ant=%x', [(frame[4] shr 3) and $1F,
      frame[4] and $07]));

    writeln;
  end;

end;

procedure outmessages(var buf: array of Byte; len: integer);
var
  i, data_i, index, shift, frame_len: integer;
begin
  i := 0;
  while (i < len) do
  begin
    if buf[i] > 1 then
    begin
      Inc(i);
      continue;
    end;
    frame_len := long_frame;
    data_i := 0;

    for index := 0 to 13 do
      adsb_frame[index] := 0;

    while ((i < len) and (buf[i] <= 1) and (data_i < frame_len)) do
    begin
      if (buf[i] = 1) then
      begin
        index := data_i div 8;
        shift := 7 - (data_i mod 8);
        adsb_frame[index] := adsb_frame[index] or Byte((1 shl shift));
      end;
      if (data_i = 7) then
      begin
        if (adsb_frame[0] = 0) then
          break;
        if ((adsb_frame[0] and $80) <> 0) then
          frame_len := long_frame
        else
          frame_len := short_frame;
      end;

      Inc(i);
      Inc(data_i);
    end;

    if (data_i < (frame_len - 1)) then
    begin
      Inc(i);
      continue;
    end;
    display(adsb_frame, frame_len);

    Inc(i);
  end;
end;

procedure ThreadProc;
var
  len: integer;
  WaitReturn: integer;
begin
  while (True) do
  begin
    WaitReturn := WaitForSingleObject(hSem, INFINITE);
    if WaitReturn = WAIT_OBJECT_0 then
    begin
      // writeln('thread on');
      CopyMemory(@thread_buf, @buf, DEFAULT_BUF_LENGTH);

      len := magnitute(thread_buf, DEFAULT_BUF_LENGTH);
      manchester(thread_buf, len);
      outmessages(thread_buf, len);

      ReleaseSemaphore(hSem, 1, nil);
      CloseHandle(hSem);
      // writeln('thread off');
    end;
  end;

  rtlsdr_cancel_async(dev);
end;

begin
  pyth_precompute;
  StopReadingSamples := False;

  try

    r := rtlsdr_open(@dev, 0);
    if (r < 0) then
      Exit;

    Log('setting frequency');
    r := rtlsdr_set_center_freq(dev, 1090000000);
    if (r >= 0) then
      Log('tuned to');
    DLog(rtlsdr_get_center_freq(dev));

    Log('set 2.000 MSPS');
    rtlsdr_set_sample_rate(dev, 2000000);
    DLog(rtlsdr_get_sample_rate(dev));

    Log('gain set to 37.8');
    rtlsdr_set_tuner_gain_mode(dev, 1);
    rtlsdr_set_tuner_gain(dev, 378);

    Log('set ppm correction');
    rtlsdr_set_freq_correction(dev, 58);

    Log('enable rtl agc');
    rtlsdr_set_agc_mode(dev, 1);

    Log('get ppm');
    DLog(rtlsdr_get_freq_correction(dev));

    r := rtlsdr_reset_buffer(dev);
    if (r < 0) then
      Log('Unable to reset buffer');

    // flush old junk
    sleep(1);
    rtlsdr_read_sync(dev, nil, 4096, nil);

    ThreadHandle := CreateThread(nil, 0, @ThreadProc, nil, 0, ThreadID);

    Log('reading samples in async mode');
    r := rtlsdr_read_async(dev, @read, nil, 32, DEFAULT_BUF_LENGTH);
    if (r < 0) then
      Log('Unable to start asynchronous reading');

    // we can not reach this point after rtlsdr_read_async

    r := rtlsdr_cancel_async(dev);
    if (r < 0) then
      Log('Unable to cancel asynchronous reading');

    Log('close');
    r := rtlsdr_close(dev);
    DLog(r);

  except
    on E: Exception do
      writeln(E.ClassName, ': ', E.Message);
  end;

end.
