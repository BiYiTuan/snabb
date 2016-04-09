local format, type, tonumber = string.format, type, tonumber

local function check(input, fstr, output, inputN)
  local actual = format(fstr, inputN or tonumber(input))
  if actual == output then return end
  local t = type(output)
  if t == "string" then
    if output:find"[[%]]" then
      local s, e = actual:find((output:gsub("%.", "%%.")))
      if s == 1 and e == #actual then return end
    end
  end
  error(format("expected string.format(%q, %q) == %q, but got %q",
    fstr, input, output, actual))
end

do --- small denormals at low precision +hexfloat !lex
  assert(("%.9e"):format(0x1.0E00D1p-1050) == "8.742456525e-317")
  assert(("%.13e"):format(0x1.1Cp-1068) == "3.5078660854729e-322")
end

do --- smoke
  local cases = {
    --     input,             %e,                 %f,            %g
    {        "0", "0.000000e+00",         "0.000000",           "0"},
    {        "1", "1.000000e+00",         "1.000000",           "1"},
    {      "0.5", "5.000000e-01",         "0.500000",         "0.5"},
    {      "123", "1.230000e+02",       "123.000000",         "123"},
    {"0.0078125", "7.812500e-03",      "0.00781[23]",   "0.0078125"},
    { "1.109375", "1.109375e+00",         "1.109375",  "1.1093[78]"},
    { "0.999995", "9.999950e-01",         "0.999995",    "0.999995"},
    {"0.9999995", "9.999995e-01",         "1.000000",           "1"},
    { "99999.95", "9.999995e+04",     "99999.950000",     "99999.9"},
    {"999999.95", "9.999999e+05",    "999999.950000",       "1e+06"},
    {"123456978", "1.234570e+08", "123456978.000000", "1.23457e+08"},
    {     "33.3", "3.330000e+01",        "33.300000",        "33.3"},
  }
  for _, t in ipairs(cases) do
    local n = tonumber(t[1])
    check(t[1], "%e", t[2], n)
    check(t[1], "%f", t[3], n)
    check(t[1], "%g", t[4], n)
  end
end

do --- easily enumerable cases of %a, %A +hexfloat
  for i = 1, 16 do
    check(1+(i-1)/16, "%.1a", "0x1.".. ("0123456789abcdef"):sub(i,i) .."p+0")
    check(16+(i-1), "%.1A", "0X1.".. ("0123456789ABCDEF"):sub(i,i) .."P+4")
  end
end

do --- easily enumerable cases of %f
  for i = 1, 16 do
    check(("1"):rep(i), "%#2.0f", ("1"):rep(i)..".")
  end
end

do --- easily enumerable cases of %e
  local z, f, c = ("0"):byte(), math.floor, string.char
  for p = 0, 14 do
    local head = "1.".. ("0"):rep(p)
    local fmt = "%#.".. c(z + f(p / 10), z + (p % 10)) .."e"
    for i = 1, 99 do
      local istr = c(z + f(i / 10), z + (i % 10))
      check("1e-".. istr, fmt, head .."e-".. istr)
      check("1e+".. istr, fmt, head .."e+".. istr)
    end
    for i = 100, 308 do
      local istr = c(z + f(i / 100), z + f(i / 10) % 10, z + (i % 10))
      check("1e-".. istr, fmt, head .."e-".. istr)
      check("1e+".. istr, fmt, head .."e+".. istr)
    end
  end
end

do --- assorted
  check("0", "%.14g", "0")
  check("1e-310", "%.0g", "1e-310")
  check("1e8", "%010.5g", "000001e+08")
  check("1e8", "% -10.5g", " 1e+08    ")
  check("4e123", "%+#.0e", "+4.e+123")
  check("1e49", "%.0f", "9999999999999999464902769475481793196872414789632")
  check("1e50", "%.0f", "100000000000000007629769841091887003294964970946560")
  check("1e50", "%.35g", "1.00000000000000007629769841091887e+50")
  check("1e50", "%40.35g", "  1.00000000000000007629769841091887e+50")
  check("1e50", "%#+40.34g", "+1.000000000000000076297698410918870e+50")
  check("1e50", "%-40.35g", "1.00000000000000007629769841091887e+50  ")
  check("0.5", "%.0f", "[01]")
  check("0.25", "%.1f", "0.[23]")
  check("999999.95", "%.7g", "999999.9")
  check("999.99995", "%.7g", "1000")
  check("6.9039613742e-314", "%.3e", "6.904e-314")

  check(1e-323, "%.99g", "9.8813129168249308835313758573644274473011960522864"..
    "9528851171365001351014540417503730599672723271985e-324")
  check(1e308, "%.99f", "1000000000000000010979063629440455417404923096773118"..
    "463368106829031575854049114915371633289784946888990612496697211725"..
    "156115902837431400883283070091981460460312716645029330271856974896"..
    "995885590433383844661650011784268976262129451776280911957867074581"..
    "22783970171784415105291802893207873272974885715430223118336.000000"..
    "000000000000000000000000000000000000000000000000000000000000000000"..
    "000000000000000000000000000")
  check("1", "%.99f", "1."..("0"):rep(99))
  check("5", "%99g", (" "):rep(98).."5")
  check("5", "%099g", ("0"):rep(98).."5")
  check("5", "%-99g", "5".. (" "):rep(98))
  check("5", "%0-99g", "5".. (" "):rep(98))

  check((2^53-1)*2^971, "%e", "1.797693e+308")
  check((2^53-1)*2^971, "%.0e", "2e+308")

  check("0", "%.14g", "0")

  check("0.15", "%.1f", "0.1")
  check("0.45", "%.1f", "0.5")
  check("0.55", "%.1f", "0.6")
  check("0.85", "%.1f", "0.8")
end

do --- assorted %a +luajit>=2.1
  check((2^53-1)*2^971, "%a", "0x1.fffffffffffffp+1023")
  check((2^53-1)*2^971, "%.0a", "0x2p+1023")
  check("0", "%a", "0x0p+0")
  check("1.53173828125", "%1.8a", "0x1.88200000p+0")
  check("1.53173828125", "%8.1a", "0x1.9p+0") -- libc on OSX gets this wrong
  check("1.5317", "%8.1a", "0x1.9p+0")
  check("1.53", "%8.1a", "0x1.8p+0")
  check("-1.5", "%11.2a", " -0x1.80p+0")
  check("3.14159265358", "%a", "0x1.921fb5443d6f4p+1")
  check("3.14159265358", "%A", "0X1.921FB5443D6F4P+1")
end

do --- Cases where inprecision can easily affect rounding
  check("2.28579528986935e-262", "%.14g", "2.2857952898694e-262")
  check("4.86009084710405e+243", "%.14g", "4.8600908471041e+243")
  check("6.28108398359615e+258", "%.14g", "6.2810839835962e+258")
  check("4.29911075733405e+250", "%.14g", "4.2991107573341e+250")
  check("8.5068432121065e+244", "% .13g", " 8.506843212107e+244")
  check("8.1919113161235899e+233", "%.40g", "8.191911316123589934222156598061"..
    "949037266e+233")
  check("7.1022381748280933e+272", "%.40g", "7.102238174828093393858336547341"..
    "897013319e+272")
  check("5.8018368514358030e+261", "%.67g", "5.801836851435803025936253580958"..
    "042578728799220447411839451694590343e+261")
  check("7.9225909325493999e-199", "%.26g", "7.922590932549399935196127e-199")
  check("2.4976643533685383e-153", "%.43g", "2.497664353368538321643894302495"..
    "469512999562e-153")
  check("9.796500001282779e+222", "%.4g", "9.797e+222")
  check("7.7169235e-227", "%e", "7.716923e-227")
  check("7.7169235000000044e-227", "%e", "7.716924e-227")
  check("5.3996444915000004e+87", "%.9e", "5.399644492e+87")
  check("2.03037546395e-49", "%.10e", "2.0303754640e-49")
  check("3.38759425741500027e+65", "%.11e", "3.38759425742e+65")
  check("1.013960434983135e-66", "%.0e", "1e-66")
  check("1.32423054454835e-204", "%.13e", "1.3242305445484e-204")
  check("5.9005060812045502e+100", "%.13e", "5.9005060812046e+100")
end

do --- ExploringBinary.com/print-precision-of-dyadic-fractions-varies-by-language/
  check(5404319552844595/2^53, "%.53g", "0.5999999999999999777955395074968691"..
	  "9152736663818359375")
  check(2^-1074, "%.99e", "4.940656458412465441765687928682213723650598026143"..
	  "247644255856825006755072702087518652998363616359924e-324")
  check(1-2^-53, "%1.53f", "0.99999999999999988897769753748434595763683319091"..
	  "796875")
end

do --- ExploringBinary.com/incorrect-floating-point-to-decimal-conversions/
  check("1.0551955", "%.7g", "1.055195")
  check("8.330400913327153", "%.15f", "8.330400913327153")
  check("9194.25055964485", "%.14g", "9194.2505596449")
  check("816.2665949149578", "%.16g", "816.2665949149578")
  check("95.47149571505499", "%.16g", "95.47149571505498")
end

do --- big f +luajit>=2.1
  check("9.522938016739373", "%.15F", "9.522938016739372")
end

do --- RandomASCII.wordpress.com/2013/02/07/
  check("6.10351562e-05", "%1.8e", "6.1035156[23]e%-05")
  check("4.3037358649999999e-15", "%1.8e", "4.30373586e-15")
end
