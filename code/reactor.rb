include Math

ACCURACY = 0.001    # when stop calculating

GP = (63.0*1000/24) # product flow rate [kg h-1]
ML = 50.0           # polymer length
TAU = 5.0           # residence time when n=1
RHO = 850.0         # density [kg m-3]
ALPHA = 1.3         # height/diameter of reactor
HP = (72.8*1000)    # heat of polymerization [J mol-1]
CV = 0.6            # conversion
T1 = (273+50)       # temperature in reactor [K]
TC = 0.128          # thermal conductivity [W m-1 K-1]
CP = (1.68*1000)    # specific heat of toluene [J kg-1 K-1]
M = 54.0            # molecular weight of butadiene [g mol-1]

class Plant
  def initialize(n, feed, coolant)
    @n = n  # number of reactors [-]
    @feed = feed  # feed [wt%]
    @rate = GP/(RHO*CV*feed)  # feed speed [m3 h-1]
    @k = (1.0/(1-CV)-1)/TAU  # reaction constant [h-1]
    @tau = (1.0/@k)*((1-CV)**(-1.0/@n)-1)  # residence time when n!=1
    @volume = @rate*@tau  # [m3]
    @diameter = (@volume/(ALPHA*2*PI))**(1/3.0)*2  # [m]
    @height = @diameter*ALPHA  # [m]
    @surface = @diameter*PI*@height  # [m2]
    @coolant = coolant  # T2 [K]
    @data = Array.new(n)  # data of each reactor
  end

  def show()
    # conditions
    puts "Conditions:"
    puts "(N, gamma_0, T2) = (#{@n}, #{@feed}, #{@coolant})"

    # reactor size
    puts "Reactor Size:"
    puts "V = #{@volume.round(3)} [m3]"
    puts "D = #{@diameter.round(3)} [m]"
    puts "H = #{@height.round(3)} [m]"

    # result of each reactor
    puts "Results:"
    for n in 0...@n
      puts "##{n+1}"
      puts "Re = #{@data[n][:re].round(3)}"
      puts "n = #{@data[n][:revolution].round(3)} [rps]"
      puts "P = #{@data[n][:power].round(3)} [W]"
    end

    # total power consumption
    total_power = 0
    @data.each do |data|
      total_power += data[:power]
    end
    puts "Total:"
    puts "Ptot = #{total_power.round(3)} [W]"
  rescue
    puts "endless calculation..."
    puts "Ptot = infinity"
  end

  def calc()
    prop = (1-CV)**(1.0/@n)  # proportional constant [-]
    for n in 0...@n
      @data[n] = reactor(@feed*(prop**(n)),@feed*(prop**(n+1)), 0)
    end
  end

  def reactor(gamma_in, gamma_out, stir_energy)
    # heat transfer rate
    heat_of_reaction = HP*(@rate*RHO*(gamma_in-gamma_out)/3.6)/M
    heat =  heat_of_reaction + stir_energy
    h = heat/@surface/(T1-@coolant)

    # viscosity [Pa s]
    viscosity = ((ML)**1.7)*((1-(gamma_out/@feed))**2.5)*exp(21.0*@feed)*1e-3

    # dimensionless numbers
    pr = viscosity*CP/TC
    nu = h*@diameter/TC
    re = (2*nu/pr**(1/3.0))**1.5

    # power consumption
    revolution = re*viscosity/RHO/(@diameter/2)**2
    np = 14.6*re**(-0.28)
    power = np*RHO*(revolution**3)*(@diameter/2)**5

    if (power - stir_energy).abs < ACCURACY
      return {
        re: re,
        revolution: revolution,
        power: power
      }
    else
      return reactor(gamma_in, gamma_out, power)
    end
  rescue SystemStackError
    return nil
  end
end

puts "input n[-], gamma_0[wt%], T2[K]"
n       = gets.to_i
feed    = gets.to_f
coolant = gets.to_i

plant = Plant.new(n, feed, coolant)
plant.calc()
plant.show()
