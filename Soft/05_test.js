//!/usr/bin/node

// POWER UP THE ADE7816 (SEE POWER AND GROUND SECTION)

// SET AND LOCK COMMUNICATION MODE (SEE COMMUNICATION SECTION)

// WRITE REQUIRED REGISTER DEFAULTS
// WTHR1 = 0x000002
// WTHR0 = 0x000000
// VARTHR1 = 0x000002
// VARTHR0 = 0x000000
// PCF_A_COEFF = 0x400CA4 (50Hz)
// PCF_B_COEFF = 0x400CA4 (50Hz)
// PCF_C_COEFF = 0x400CA4 (50Hz)
// PCF_D_COEFF = 0x400CA4 (50Hz)
// PCF_E_COEFF = 0x400CA4 (50Hz)
// PCF_F_COEFF = 0x400CA4 (50Hz)
// DICOEFF = 0xFFF8000

// CONFIGURE METER SPECIFIC INTERRUPTS, POWER QUALITY FEATURES, AND CALIBRATE
// (SEE THE INTERRUPTS, POWER QUALITY FEATURES, AND ENERGY CALIBRATION SECTIONS)

// NOTE THAT THE FINAL REGISTER SHOULD BE WRITTEN 3 TIMES TO CLEAR THE BUFFER
// (SEE STARTING AND STOPPING THE DSP SECTION)

// ENABLE THE ENERGY METERING DSP (SEE STARTING AND STOPPING THE DSP SECTION)

const VGAIN = 0x4380
const IAGAIN = 0x4381
const IBGAIN = 0x4382
const ICGAIN = 0x4383
const IDGAIN = 0x4384
const IEGAIN = 0x4385
const IFGAIN = 0x4386
const DICOEFF = 0x4388
const HPFDIS = 0x4389
const VRMSOS = 0x438A
const IARMSOS = 0x438B
const IBRMSOS = 0x438C
const ICRMSOS = 0x438D
const IDRMSOS = 0x438E
const IERMSOS = 0x438F
const IFRMSOS = 0x4390
const AWGAIN = 0x4391
const AWATTOS = 0x4392
const BWGAIN = 0x4393
const BWATTOS = 0x4394
const CWGAIN = 0x4395
const CWATTOS = 0x4396
const DWGAIN = 0x4397
const DWATTOS = 0x4398
const EWGAIN = 0x4399
const EWATTOS = 0x439A
const FWGAIN = 0x439B
const FWATTOS = 0x439C
const AVARGAIN = 0x439D
const AVAROS = 0x439E
const BVARGAIN = 0x439F
const BVAROS = 0x43A0
const CVARGAIN = 0x43A1
const CVAROS = 0x43A2
const DVARGAIN = 0x43A3
const DVAROS = 0x43A4
const EVARGAIN = 0x43A5
const EVAROS = 0x43A6
const FVARGAIN = 0x43A7
const FVAROS = 0x43A8
const WTHR1 = 0x43AB
const WTHR0 = 0x43AC
const VARTHR1 = 0x43AD
const VARTHR0 = 0x43AE
const APNOLOAD = 0x43AF

const VARNOLOAD = 0x43B0
const PCF_A_COEFF = 0x43B1
const PCF_B_COEFF  = 0x43B2
const PCF_C_COEFF  = 0x43B3
const PCF_D_COEFF  = 0x43B4
const PCF_E_COEFF  = 0x43B5
const PCF_F_COEFF  = 0x43B6
const VRMS = 0x43C0
const IARMS = 0x43C1
const IBRMS = 0x43C2
const ICRMS = 0x43C3
const IDRMS = 0x43C4
const IERMS = 0x43C5
const IFRMS  = 0x43C6

const RUN = 0xE228

const AWATTHR = 0xE400
const BWATTHR = 0xE401
const CWATTHR = 0xE402
const DWATTHR = 0xE403
const EWATTHR = 0xE404
const FWATTHR = 0xE405
const AVARHR = 0xE406
const BVARHR = 0xE407
const CVARHR = 0xE408
const DVARHR = 0xE409
const EVARHR = 0xE40A
const FVARHR = 0xE40B

const VPEAK = 0xE501
const STATUS0 = 0xE502
const STATUS1 = 0xE503
const OILVL = 0xE507
const OVLVL = 0xE508
const SAGLVL = 0xE509
const MASK0 = 0xE50A
const MASK1 = 0xE50B
const IAWV_IDWV = 0xE50C
const IBWV_IEWV = 0xE50D
const ICWV_IFWV = 0xE50E
const VWV = 0xE510
const CHECKSUM = 0xE51F
const CHSTATUS = 0xE600
const ANGLE0 = 0xE601
const ANGLE1 = 0xE602
const ANGLE2 = 0xE603
const PERIOD = 0xE607
const CHNOLOAD = 0xE608
const LINECYC = 0xE60C
const ZXTOUT = 0xE60D
const COMPMODE = 0xE60E
const GAIN = 0xE60F
const CHSIGN = 0xE617
const CONFIG = 0xE618
const MMODE = 0xE700
const ACCMODE = 0xE701
const LCYCMODE = 0xE702
const PEAKCYC = 0xE703
const SAGCYC = 0xE704
const HSDC_CFG = 0xE706
const VERSION  = 0xE707
const SPISELECT = 0xEBFF
const CONFIG2  = 0xEC01

function parseBytes(v, n, p) {
  var a = new Array(n)
  for(var i = 1; i <= n; i++) {
    var shift = (i-1) * 8
    a[n-i] = (v >>> shift) & 0xFF
  }
  // padding 'ZPSE' or 'SE' for 24 bit registers with 32 bit communication
  if (n == 4 && p == 'ZPSE' && a[1] & 0x80) a[0] = 0x0F
  if (n == 4 && p == 'SE' && a[1] & 0x80) a[0] = 0xFF
  return a
}

function i2cWriteSeq(addr, buf) {
  var a = new Array(parseBytes(addr, 2), buf)
  return Buffer(Array.prototype.concat.apply([], a))
}

function i2cReadSeq(addr) {
  var a = new Array(parseBytes(addr, 2))
  return Buffer(Array.prototype.concat.apply([], a))
}

function i2cWrite(addr, data, n, p) {
  // i2c, bufIn and BufOut are global variables
  bufIn = i2cWriteSeq(addr, parseBytes(data, n, p))
  bufOut = i2c.write(bufIn)
  return bufOut
}

function i2cWriteRepeat() {
  // i2c, bufIn and BufOut are global variables
  bufOut = i2c.write(bufIn)
  return bufOut
}

function i2cRead(addr, n) {
  // i2c, bufIn and BufOut are global variables
  bufIn = i2cReadSeq(addr)
  i2c.write(bufIn)
  bufOut = i2c.read(n)
  return bufOut
}

var m = require('mraa')
var i2c = new m.I2c(0)
var bufIn = new Buffer(0)
var bufOut = new Buffer(0)

i2c.address(0x38)
i2c.frequency(100000)

// Soft reset
//i2cWrite(CONFIG, 0x0080, 2)
//i2cWrite(CONFIG, 0x0000, 2)

// Setup registers
i2cWrite(WTHR1, 0x000002, 4)
i2cWrite(WTHR0, 0x000000, 4)
i2cWrite(VARTHR1, 0x000002, 4)
i2cWrite(VARTHR0, 0x000000, 4)
i2cWrite(PCF_A_COEFF, 0x400CA4, 4, 'ZPSE')
i2cWrite(PCF_B_COEFF, 0x400CA4, 4, 'ZPSE')
i2cWrite(PCF_C_COEFF, 0x400CA4, 4, 'ZPSE')
i2cWrite(PCF_D_COEFF, 0x400CA4, 4, 'ZPSE')
i2cWrite(PCF_E_COEFF, 0x400CA4, 4, 'ZPSE')
i2cWrite(PCF_F_COEFF, 0x400CA4, 4, 'ZPSE')
i2cWrite(DICOEFF, 0xFF8000, 4, 'ZPSE')

// HSDC output
i2cWrite(HSDC_CFG, 0x08, 1) // 0x08 or 0x09 or 0x0C or 0x0D
i2cWrite(CONFIG, 0x0040, 2)

// accumulation mode
//v = i2cRead(LCYCMODE, 1)
//v[0] = v[0] & 0xBF
//i2cWrite(LCYCMODE, v, 1)

// Repeat the last command 3 times
i2cWriteRepeat()
i2cWriteRepeat()

// RUN DSP
i2cWrite(RUN, 0x0001, 2)

//
var id = setInterval(function() {
    console.log('--------------------')
    voltage = i2cRead(VWV, 4)
    console.log('Voltage: ' + voltage.readInt32BE(0) + '(' + voltage.toString('hex') + ')')
    //    i2cWrite(COMPMODE, 0x01FF, 2)
    current = i2cRead(IAWV_IDWV, 4)
    console.log('Current A: ' + current.readInt32BE(0) + '(' + current.toString('hex') + ')')
    current = i2cRead(IBWV_IEWV, 4)
    console.log('Current B: ' + current.readInt32BE(0) + '(' + current.toString('hex') + ')')
    current = i2cRead(ICWV_IFWV, 4)
    console.log('Current C: ' + current.readInt32BE(0) + '(' + current.toString('hex') + ')')
    //    i2cWrite(COMPMODE, 0x41FF, 2)
    current = i2cRead(IAWV_IDWV, 4)
    console.log('Current D: ' + current.readInt32BE(0) + '(' + current.toString('hex') + ')')
    current = i2cRead(IBWV_IEWV, 4)
    console.log('Current E: ' + current.readInt32BE(0) + '(' + current.toString('hex') + ')')
    current = i2cRead(ICWV_IFWV, 4)
    console.log('Current F: ' + current.readInt32BE(0) + '(' + current.toString('hex') + ')')
    console.log('Energy A: ' + i2cRead(AWATTHR, 4).readInt32BE(0))
    console.log('Energy B: ' + i2cRead(BWATTHR, 4).readInt32BE(0))
    console.log('Energy C: ' + i2cRead(CWATTHR, 4).readInt32BE(0))
    console.log('Energy D: ' + i2cRead(DWATTHR, 4).readInt32BE(0))
    console.log('Energy E: ' + i2cRead(EWATTHR, 4).readInt32BE(0))
    console.log('Energy F: ' + i2cRead(FWATTHR, 4).readInt32BE(0))
}, 1000)
