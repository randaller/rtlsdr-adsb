unit rtlsdr;

interface

uses Windows;

const
  rtldll = 'rtlsdr.dll';

{
type
  rtlsdr_dev = ^rtlsdr_dev_t;
  rtlsdr_dev_t = record
  end;
}

{$MINENUMSIZE 4}
type
  Trtlsdr_tuner = (
    RTLSDR_TUNER_UNKNOWN = 0,
    RTLSDR_TUNER_E4000,
    RTLSDR_TUNER_FC0012,
    RTLSDR_TUNER_FC0013,
    RTLSDR_TUNER_FC2580,
    RTLSDR_TUNER_R820T,
    RTLSDR_TUNER_R828D
  );

// typedef void(*rtlsdr_read_async_cb_t)(unsigned char *buf, uint32_t len, void *ctx);
type
  Trtlsdr_read_async_cb_t = procedure(
    buf: PAnsiChar;
    len: UINT32;
    ctx: Pointer
  );

// RTLSDR_API uint32_t rtlsdr_get_device_count(void);
function rtlsdr_get_device_count(): UINT32; stdcall; external rtldll;

// RTLSDR_API const char* rtlsdr_get_device_name(uint32_t index);
function rtlsdr_get_device_name(index: UINT32): PAnsiChar; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_device_usb_strings(uint32_t index, char *manufact, char *product, char *serial);
function rtlsdr_get_device_usb_strings(index: UINT32;
    manufact, product, serial: PAnsiChar): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_index_by_serial(const char *serial);
function rtlsdr_get_index_by_serial(const serial: PAnsiChar): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_open(rtlsdr_dev_t **dev, uint32_t index);
function rtlsdr_open(rtlsdr_dev_t: Pointer; index: UINT32): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_close(rtlsdr_dev_t *dev);
function rtlsdr_close(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_xtal_freq(rtlsdr_dev_t *dev, uint32_t rtl_freq, uint32_t tuner_freq);
function rtlsdr_set_xtal_freq(rtlsdr_dev_t: Pointer;
    rtl_freq, tuner_freq: UINT32): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_xtal_freq(rtlsdr_dev_t *dev, uint32_t *rtl_freq, uint32_t *tuner_freq);
function rtlsdr_get_xtal_freq(rtlsdr_dev_t: Pointer;
    rtl_freq, tuner_freq: PInteger): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_usb_strings(rtlsdr_dev_t *dev, char *manufact, char *product, char *serial);
function rtlsdr_get_usb_strings(rtlsdr_dev_t: Pointer;
    manufact, product, serial: PAnsiChar): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_write_eeprom(rtlsdr_dev_t *dev, uint8_t *data, uint8_t offset, uint16_t len);
function rtlsdr_write_eeprom(rtlsdr_dev_t: Pointer;
    data: Pointer; offset: UINT8; len: UINT16): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_read_eeprom(rtlsdr_dev_t *dev, uint8_t *data, uint8_t offset, uint16_t len);
function rtlsdr_read_eeprom(rtlsdr_dev_t: Pointer;
    data: Pointer; offser: UINT8; len: UINT16): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_center_freq(rtlsdr_dev_t *dev, uint32_t freq);
function rtlsdr_set_center_freq(rtlsdr_dev_t: Pointer; freq: UINT32): Integer; stdcall; external rtldll;

// RTLSDR_API uint32_t rtlsdr_get_center_freq(rtlsdr_dev_t *dev);
function rtlsdr_get_center_freq(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_freq_correction(rtlsdr_dev_t *dev, int ppm);
function rtlsdr_set_freq_correction(rtlsdr_dev_t: Pointer; ppm: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_freq_correction(rtlsdr_dev_t *dev);
function rtlsdr_get_freq_correction(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API enum rtlsdr_tuner rtlsdr_get_tuner_type(rtlsdr_dev_t *dev);
function rtlsdr_get_tuner_type(rtlsdr_dev_t: Pointer): Trtlsdr_tuner; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_tuner_gains(rtlsdr_dev_t *dev, int *gains);
function rtlsdr_get_tuner_gains(rtlsdr_dev_t: Pointer; gains: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_tuner_gain(rtlsdr_dev_t *dev, int gain);
function rtlsdr_set_tuner_gain(rtlsdr_dev_t: Pointer; gain: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_tuner_gain(rtlsdr_dev_t *dev);
function rtlsdr_get_tuner_gain(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_tuner_if_gain(rtlsdr_dev_t *dev, int stage, int gain);
function rtlsdr_set_tuner_if_gain(rtlsdr_dev_t: Pointer; stage, gain: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_tuner_gain_mode(rtlsdr_dev_t *dev, int manual);
function rtlsdr_set_tuner_gain_mode(rtlsdr_dev_t: Pointer; manual: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_sample_rate(rtlsdr_dev_t *dev, uint32_t rate);
function rtlsdr_set_sample_rate(rtlsdr_dev_t: Pointer; rate: UINT32): Integer; stdcall; external rtldll;

// RTLSDR_API uint32_t rtlsdr_get_sample_rate(rtlsdr_dev_t *dev);
function rtlsdr_get_sample_rate(rtlsdr_dev_t: Pointer): UINT32; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_testmode(rtlsdr_dev_t *dev, int on);
function rtlsdr_set_testmode(rtlsdr_dev_t: Pointer; on: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_agc_mode(rtlsdr_dev_t *dev, int on);
function rtlsdr_set_agc_mode(rtlsdr_dev_t: Pointer; on: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_direct_sampling(rtlsdr_dev_t *dev, int on);
function rtlsdr_set_direct_sampling(rtlsdr_dev_t: Pointer; on: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_direct_sampling(rtlsdr_dev_t *dev);
function rtlsdr_get_direct_sampling(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_set_offset_tuning(rtlsdr_dev_t *dev, int on);
function rtlsdr_set_offset_tuning(rtlsdr_dev_t: Pointer; on: Integer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_get_offset_tuning(rtlsdr_dev_t *dev);
function rtlsdr_get_offset_tuning(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_reset_buffer(rtlsdr_dev_t *dev);
function rtlsdr_reset_buffer(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_read_sync(rtlsdr_dev_t *dev, void *buf, int len, int *n_read);
function rtlsdr_read_sync(rtlsdr_dev_t: Pointer;
    buf: Pointer; len: Integer; n_read: PInteger): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_wait_async(rtlsdr_dev_t *dev, rtlsdr_read_async_cb_t cb, void *ctx);
function rtlsdr_wait_async(rtlsdr_dev_t: Pointer;
    cb: Trtlsdr_read_async_cb_t; ctx: Pointer): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_read_async(rtlsdr_dev_t *dev, rtlsdr_read_async_cb_t cb, void *ctx, uint32_t buf_num, uint32_t buf_len);
function rtlsdr_read_async(rtlsdr_dev_t: Pointer;
    cb: Trtlsdr_read_async_cb_t; ctx: Pointer; buf_num: UINT32; buf_len: UINT32): Integer; stdcall; external rtldll;

// RTLSDR_API int rtlsdr_cancel_async(rtlsdr_dev_t *dev);
function rtlsdr_cancel_async(rtlsdr_dev_t: Pointer): Integer; stdcall; external rtldll;

implementation
end.
