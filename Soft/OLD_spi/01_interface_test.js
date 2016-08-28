#!/usr/bin/node

var m = require('mraa')

function char(x) { return parseInt(x, 16); }

x = new m.Spi(0)
x.frequency(1000000)

buf = new Buffer(7)
buf[0] = char('0x01')
buf[1] = char('0x43')
buf[2] = char('0x80')
buf[3] = char('0x00')
buf[4] = char('0x00')
buf[5] = char('0x00')
buf[6] = char('0x00')

buf2 = x.write(buf)
console.log("Sent: " + buf.toString('hex') + ". Received: " + buf2.toString('hex'))

buf[0] = char('0x01')
buf[1] = char('0xe5')
buf[2] = char('0x1f')
buf[3] = char('0x00')
buf[4] = char('0x00')
buf[5] = char('0x00')
buf[6] = char('0x00')

buf2 = x.write(buf)
console.log("Sent: " + buf.toString('hex') + ". Received: " + buf2.toString('hex'))
