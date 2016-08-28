#!/usr/bin/ruby

ARGF.each do |line|
  if line[/(fp_text reference (C)\d+ \(at [-]*[\d\.]+) ([-]*)([\d\.]+)/] then
    #puts $3 + " " + "%.1f" % ($3.to_f - 0.4)
    #puts line
    puts $` + $1 + " " + $3 + ("%.1f" % ($4.to_f - 0.4)) + $'
  else
    puts line
  end
end
