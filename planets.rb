class Planets
private
  refd = -3543.0
  refDate = "19 april 1990"
  precessionFactor = "%f" % "3.82394E-5"

  @@orbitals = {
    :sun => {
      n1: 0.0,
      n2: 0.0,
      i1: 0.0,             
      i2: 0.0,
      w1: 282.9404,
      w2: "4.70935E-5".to_f,
      a: 1.0,
      e1: 0.016709,
      e2: "1.151E-9".to_f,
      m1: 356.0470,
      m2: 0.9856002585,
      oblecl1: 23.4393,
      oblecl2: "3.563E-7".to_f,
      size: 69634, #size: 696342,
    },
    :mercury => {
      n1:  48.3313,
      n2: "3.24587E-5".to_f,
      i1: 7.0047,
      i2: "5.00E-8".to_f,
      w1:  29.1241,
      w2: "1.01444E-5".to_f,
      a: 0.387098,
      e1: 0.205635,
      e2: "5.59E-10".to_f,
      m1: 168.6562,
      m2: 4.0923344368,
      size: 2439,
    },
    :venus => {
      n1:  76.6799,
      n2: "2.46590E-5".to_f,
      i1: 3.3946,
      i2: "2.75E-8".to_f,
      w1:  54.8910,
      w2: "1.38374E-5".to_f,
      a: 0.723330,
      e1: 0.006773,
      e2: "1.302E-9".to_f,
      m1:  48.0052,
      m2: 1.6021302244,
      size: 6051,
    },
    :mars => {
      n1:  49.5574,
      n2: "2.11081E-5".to_f,
      i1: 1.8497,
      i2: "1.78E-8".to_f,
      w1: 286.5016,
      w2: "2.92961E-5".to_f ,
      a: 1.523688 ,
      e1: 0.093405,
      e2: "2.516E-9".to_f,
      m1:  18.6021,
      m2: 0.5240207766,
      size: 3389,
    },
    :jupiter => {
      n1: 100.4542,
      n2: "2.76854E-5".to_f,
      i1: 1.3030 ,
      i2: "1.557E-7".to_f,
      w1: 273.8777,
      w2: "1.64505E-5".to_f,
      a: 5.20256 ,
      e1: 0.048498,
      e2: "4.469E-9".to_f,
      m1:  19.8950,
      m2: 0.0830853001,
      size: 69911,
    },
    :saturn => {
      n1: 113.6634,
      n2: "2.38980E-5".to_f,
      i1: 2.4886,
      i2: "1.081E-7".to_f,
      w1: 339.3939,
      w2: "2.97661E-5".to_f,
      a: 9.55475 ,
      e1: 0.055546,
      e2: "9.499E-9".to_f,
      m1: 316.9670,
      m2: 0.0334442282,
      size: 58232,
    },
    :uranus => {
      n1:  74.0005,
      n2: "1.3978E-5".to_f,
      i1: 0.7733,
      i2: "1.9E-8".to_f,
      w1:  96.6612,
      w2: "3.0565E-5".to_f,
      a1: 19.189253, #19.18171,
      a2: "1.55E-8 ".to_f,
      e1: 0.047220087, #0.047318,
      e2: "7.45E-9".to_f,
      m1: 142.5905,
      m2: 0.011725806,
      size: 25362,
    },
    :neptune => {
      n1: 131.7806,
      n2: "3.0173E-5".to_f,
      i1: 1.7700,
      i2: "2.55E-7".to_f,
      w1: 272.8461,
      w2: "6.027E-6".to_f,
      a1: 30.05826,
      a2: "3.313E-8 ".to_f,
      e1: 0.008606,
      e2: "2.15E-9".to_f,
      m1: 260.2471,
      m2: 0.005995147,
      size: 24622,
    }
  } 
  @path

  def initialize()
    @path={}
    @@orbitals.each_key{|k| @path[k]=[]}
  end

  def adjustByDate(orbital, day)
    orbital[:n] = orbital[:n1] + day*orbital[:n2]
    orbital[:i] = orbital[:i1] + day*orbital[:i2]
    orbital[:w] = orbital[:w1] + day*orbital[:w2]
    orbital[:e] = orbital[:e1] + day*orbital[:e2]
    orbital[:m] = orbital[:m1] + day*orbital[:m2]
    orbital[:a] = orbital[:a1] + day*orbital[:a2] if orbital.has_key?(:a1)
    orbital[:oblecl] = orbital[:oblecl1] + day*orbital[:oblecl2] if orbital.has_key?(:oblecl1)
    return orbital
  end


  def getCoordinates(ra, decl, r)
    x = r * Math::cos(ra) * Math::cos(decl)
    y = r * Math::sin(ra) * Math::cos(decl)
    z = r * Math::sin(decl)
    return [x,y,z]
  end

  def rotateEclipticToEquitorial(xeclip,yeclip,zeclip, oblecl)
    xequat = xeclip
    yequat = yeclip * Math::cos(oblecl) - zeclip * Math::sin(oblecl)
    zequat = yeclip * Math::sin(oblecl) + zeclip * Math::cos(oblecl)
    return [xequat, yequat, zequat]
  end

  def calcEIterative(orbital)
    e0 = orbital[:e]
    e1=0
    while ( (e0 - e1).abs > 0.001)
      e1 = e0 - ( e0 - orbital[:e]*(180/Math::PI) * Math::sin(e0) - orbital[:m] ) / ( 1 - orbital[:e] * Math::cos(e0) )
      e0 = e1
    end
    return e1
  end

  def calcEcentricAnomaly(adjusted)
    if adjusted[:e] < 0.06
      ecentricAnomaly = adjusted[:m] + adjusted[:e]*(180/Math::PI) * Math::sin(adjusted[:m]) * ( 1.0 + adjusted[:e] * Math::cos(adjusted[:m]) )
    else
      ecentricAnomaly = calcEIterative(adjusted)
    end
  end

  def calcDistanceAnomaly(orbital,ecentricAnomaly)
    #puts "orbital"
    #orbital.each{|key,value| puts "#{key}:#{value}"}

    xv = orbital[:a] * ( Math::cos(ecentricAnomaly) - orbital[:e] )
    yv = orbital[:a] * ( Math::sqrt(1.0 - orbital[:e]*orbital[:e]) * Math::sin(ecentricAnomaly) )

    v = Math::atan2( yv, xv )
    r = Math::sqrt( xv*xv + yv*yv )
    return {r: r, v: v}
  end

  def calcEclipticPos(orbital, distAnom)
    orbital[:x] = distAnom[:r] * ( Math::cos(orbital[:n]) * Math::cos(distAnom[:v]+orbital[:w]) - Math::sin(orbital[:n]) * Math::sin(distAnom[:v]+orbital[:w]) * Math::cos(orbital[:i]) )
    orbital[:y] = distAnom[:r] * ( Math::sin(orbital[:n]) * Math::cos(distAnom[:v]+orbital[:w]) + Math::cos(orbital[:n]) * Math::sin(distAnom[:v]+orbital[:w]) * Math::cos(orbital[:i]) )
    orbital[:z] = distAnom[:r] * ( Math::sin(distAnom[:v]+orbital[:w]) * Math::sin(orbital[:i]) )
    orbital[:lon] = Math::atan2( orbital[:y], orbital[:x] )
    orbital[:lat] = Math::atan2( orbital[:z], Math::sqrt(orbital[:x]*orbital[:x]+orbital[:y]*orbital[:y]) )
    return orbital
  end

  def getPrecessionCorrection(epoch, d)
    lon_corr =  precessionFactor * ( 365.2422 * ( epoch - 2000.0 ) - d )
  end

  def convertLatLonToXYZ(orbital, distAnom)
    orbital[:x] = distAnom[:r] * Math::cos(orbital[:lon]) * Math::cos(orbital[:lat])
    orbital[:y] = distAnom[:r] * Math::sin(orbital[:lon]) * Math::cos(orbital[:lat])
    orbital[:z] = distAnom[:r] * Math::sin(orbital[:lat])

    return orbital
  end

  def correctPertuberations(orbital, name, day, distAnom)
    mj = adjustByDate(@@orbitals[:jupiter], day)[:m]
    ms = adjustByDate(@@orbitals[:saturn], day)[:m]
    mu = adjustByDate(@@orbitals[:uranus], day)[:m]

    case name 
    when :jupiter
      orbital[:lon] += 0
      -0.332 * Math::sin(2*mj - 5*ms - 67.6)
      -0.056 * Math::sin(2*mj - 2*ms + 21)
      +0.042 * Math::sin(3*mj - 5*ms + 21)
      -0.036 * Math::sin(mj - 2*ms)
      +0.022 * Math::cos(mj - ms)
      +0.023 * Math::sin(2*mj - 3*ms + 52)
      -0.016 * Math::sin(mj - 5*ms - 69)
      orbital = convertLatLonToXYZ(orbital, distAnom)
    when :saturn
      orbital[:lon] += 0
      +0.812 * Math::sin(2*mj - 5*ms - 67.6)
      -0.229 * Math::cos(2*mj - 4*ms - 2)
      +0.119 * Math::sin(mj - 2*ms - 3)
      +0.046 * Math::sin(2*mj - 6*ms - 69)
      +0.014 * Math::sin(mj - 3*ms + 32)

      orbital[:lat] += 0
      -0.020 * Math::cos(2*mj - 4*ms - 2)
      +0.018 * Math::sin(2*mj - 6*ms - 49)
      orbital = convertLatLonToXYZ(orbital, distAnom)
    when :uranus
      orbital[:lon] += 0
      +0.040 * Math::sin(ms - 2*mu + 6)
      +0.035 * Math::sin(ms - 3*mu + 33)
      -0.015 * Math::sin(mj - mu + 20)
      orbital = convertLatLonToXYZ(orbital, distAnom)
    end
    
    return orbital
  end
  
public  
  def planetHelioEclipticOn(orbital, name, day)
    adjusted = adjustByDate(orbital, day)
    ecentricAnomaly = calcEcentricAnomaly(adjusted)
    distAnom = calcDistanceAnomaly(adjusted, ecentricAnomaly)
    eclipticPos = calcEclipticPos(adjusted, distAnom)
    pertuberatedPos = correctPertuberations(eclipticPos, name, day, distAnom)
    #precession
    #eclPos[:lon] += getPrecessionCorrection(epoch, day)
    #eclPos[:lat] += getPrecessionCorrection(epoch, day) unless isMoon
    
    return pertuberatedPos
  end

  def planetHelioEquatorialOn(orbital, name, day)
    pos = planetHelioEclipticOn(orbital, name, day)
    ecl = 23.4393 - "3.563E-7".to_f * day
    
    pos[:x] = pos[:x]
    pos[:y] = pos[:y] * Math::cos(ecl) - pos[:z] * Math::sin(ecl)
    pos[:z] = pos[:y] * Math::sin(ecl) + pos[:z] * Math::cos(ecl)
    return pos
  end

  def getPaths
    return @path
  end
  
  def simulateOneStep(delta_t)
    orbitals = @@orbitals.inject({}){|res, (name, orbital)| res[name]=planetHelioEquatorialOn(orbital, name, delta_t); res[name][:size]=orbital[:size]; res }
    orbitals.map.with_index{|(name,orbital), i| @path[name].push( [orbital[:x],orbital[:y],orbital[:z]] ) }
    return orbitals
  end

  def self.getPlanetList
    @@orbitals.keys
  end
  #http://www.stjarnhimlen.se/comp/ppcomp.html
end
