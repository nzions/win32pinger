
# pinger
#
# pings devices and shows results
# loads ping targes either from pinger.txt or file specified on command line

require 'Win32API'

def setcolor(color=7)
	handle = Win32API.new( "kernel32", "GetStdHandle", ['l'], 'l' ).call(0xFFFFFFF5)
	wapi = Win32API.new( "kernel32", "SetConsoleTextAttribute", ['l', 'i'], 'l' )
	att = color
	# white = 7
	# green = 2
	# red = 4
	wapi.call(handle,att)
end

class Device
	attr_accessor :name, :ip, :rtt
	def initialize(name,ip)
		@name = name
		@ip = ip
		@rtt = 0
		@state = "Down"
		@timer = Time.now.to_i
	end
	
	def set_state(state)
		if (state != @state)
			$log << "#{Time.now.strftime("%I:%M:%S")} | #{@name.ljust(15)} #{state} was #{@state} for #{(Time.now - @timer).to_i}s"
			@state = state
			@timer = Time.now.to_i
		end
	end
	
	def state
		@state
	end
	
	def timer
		Time.now.to_i - @timer
	end
end

def ping(obj)
	ploss = nil;
	state = "Down"

	c = "ping -n 2 -w 2000 #{obj.ip}"
	f = IO.popen(c)
	f.readlines.each do |l|
		if l.match(/time=/)
			state = "Up"
		end
	end
	f.close
	
	obj.set_state(state)
end

def writestats(obj)
	
	name = obj.name[0..19].ljust(20)
	ip = obj.ip.ljust(15)
	state = "#{obj.state.ljust(4)} #{obj.timer}s"
	state = state.ljust(12)
	
	if (obj.state == "Up")
		setcolor(2)
	elsif (obj.state == "Down")
		setcolor(4)
	else
		setcolor(7)
	end
	
	puts "#{name} #{ip} #{state}"
	
	setcolor(7)
end

def loadconfig(file)
	ret = Array.new
	begin
		File.open(file).each do |l|
			if l.match("^ping:")
				l.chomp!
				parts = l.split(":")
				ret << Device.new(parts[1],parts[2])
			end
		end
	rescue
		puts "could not load config from #{file}"
		exit 1
	end
	return ret
end

cfile = "pinger.txt"
cfile = ARGV[0] if ARGV[0]
devices = loadconfig(cfile)
$log = Array.new()


puts "Loaded #{devices.length} Devices"

iteration = 0
while true do
	system("cls")

	puts "Iteration #{iteration}"
	puts
	devices.each do |y|
		writestats(y)
	end
	puts
	puts
	
	
	puts "----------------------------------------------"
	i = 1
	$log.reverse.each do |l|
		break if i > 7
		i += 1
		
		if l.match("Up was")
			setcolor(2)
		elsif l.match("Down was")
			setcolor(4)
	
		end
		puts l
		setcolor(7)
	end
	puts
	puts
	
	devices.each do |y|
		Thread.new do
			ping(y)
		end
	end
	
	Thread.list.each do |t|
		next if t == Thread.main
		t.join
	end
	
	iteration += 1
end

