
require "matrix"

require_relative 'planet_simulator'
#cartesian state vectors
#from NASA Horizons ephemeris database
#date of 28-01-2015
# units: mass:kg size:km state:AU/d

class PlanetsRelativistic < PlanetSimulator
ORBITALS = {
  sun: {
    mass: 1.988544e+30,
    size: 6.955e+5,
    state: [2.907709086857369E-03, -7.651832268497074E-04, -1.388689829884795E-04,  3.869865713775272E-06,  5.349727162294384E-06, -9.652291914166599E-08],
  },
  mercury: {
    mass: 3.302e+23,
    size: 2440,
    state: [ 1.898790092866500E-01,  2.492283708455527E-01,  3.133919848377940E-03, -2.811752786548214E-02,  1.800615372814728E-02,  4.050745176714573E-03,],
  },
  venus: {
    mass: 48.685e+23,
    size: 6051.8,
    state: [ 7.075088829150125E-01, -1.759644371817919E-01, -4.320190225092103E-02,  4.781352469919346E-03,  1.954433958417331E-02, -8.005284366507023E-06,]
  },
  earth: {
    mass: 5.97219e+24,
    size: 6378.14,
    state: [-4.489079145002344E-01,  8.731839958634132E-01, -1.688204679979873E-04, -1.556616570859346E-02, -7.960372562529740E-03,  1.851675964089028E-08],
  },
  moon: {
    mass: 734.9e+20,
    size: 1737.53,
    state: [-4.492295947663176E-01,  8.707279819223681E-01,  3.532397583977436E-05, -1.495617961331058E-02, -8.000806015456890E-03,  1.571677110616910E-05,],
  },        
  mars: {
    mass: 6.4185e+23,
    size: 3389.9,
    state: [1.393150852383604E+00, -1.930716347650592E-02, -3.465000800332729E-02,  7.287913176878839E-04,  1.519430754663038E-02,  3.003676687387126E-04,]
  },
  jupiter: {
    mass: 1898.13e+24,
    size: 71492,
    state: [-3.818533115280017E+00,  3.708486729998566E+00,  6.996696549033075E-02, -5.347079172505289E-03, -5.057462849903937E-03,  1.406813513774063E-04,],
  },
  saturn: {
    mass: 5.68319e+26,
    size: 60268,
    state: [-5.330900199925463E+00, -8.401361779789443E+00,  3.582396994982406E-01,  4.405819144860358E-03, -3.005375858516388E-03, -1.227361157888920E-04,],
  },
  uranus: {
    mass: 86.8103e+24,
    size: 25559,
    state: [1.928855659399567E+01,  5.311465633553790E+00, -2.301623218413382E-01, -1.072910755275677E-03,  3.608609048091818E-03,  2.714813922208130E-05,],
  },
  neptune: {
    mass: 102.41e+24,
    size: 24766,
    state: [ 2.755016840671880E+01, -1.179490673948398E+01, -3.920282227719774E-01,  1.214149496744588E-03,  2.904164417775375E-03, -8.768697263222662E-05,],
  },            
  pluto: {
    mass:  1.307e+22,
    size: 1195,
    state: [ 7.453060957291160E+00, -3.191868512209607E+01,  1.259619224615070E+00,  3.109684526995636E-03,  6.345743444144480E-05, -9.099546568174587E-04,]
  },
}

  G = 6.673e-11
  AU = 1.4959787e+11 #m 1.5e+8 #km
  Day = 24*3600 #s

  
  public
  def initialize
    print "prepare orbital data ..."
    ORBITALS.each do |name, orb|
      state = orb[:state]
      orb[:pos] = Vector.[](*state[0..2]) * AU 
      orb[:vel] = Vector.[](*state[3..5]) * AU / Day
      orb[:size] = orb[:size].to_f / 1e+1 if name == :sun
    end

    @paths={}
    ORBITALS.each_key{|k| @paths[k]=[]}

    puts "done"
  end
  
  def twoBodyAttractionForce(orb1, orb2)
    diff =orb2[:pos]-orb1[:pos]
    abs = diff.norm
    force =  (abs != 0)? orb2[:mass]*(diff/abs**3) : Vector[0,0,0]
  end

  def updatePosition(orb1, delta_t)
    forces = ORBITALS.inject(Vector[0,0,0]){|memo, (name,orb2)| memo+twoBodyAttractionForce(orb1,orb2)}
      
#    totalForce =G*orb1[:mass] * forces
#    accel = totalForce / orb1[:mass]

    accel = G*  forces
    velocity = orb1[:vel]+accel*delta_t
    orb1[:vel] = velocity
    pos = orb1[:pos] + velocity*delta_t

    return pos 
  end

  
  def getPaths
    @paths
  end
  
  def simulateOneStep(delta_t)
    delta_t *= Day
    
    ORBITALS.each{|name, orb| orb[:pos]  = updatePosition(orb, delta_t) }

    #filter output information
    return ORBITALS.inject({}) do|memo, (name,orb)|
      pos = orb[:pos] / AU
      @paths[name].push(pos)

      memo[name] = {x: pos[0],y: pos[1],z: pos[2], size: orb[:size]};
      memo
    end
  end

  def getPlanetList
    ORBITALS.keys
  end

end
