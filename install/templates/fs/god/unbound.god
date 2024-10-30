God.watch do |w|
  w.name = "unbound"
  w.group = "mailserv"
  w.interval = 30.seconds # default
  w.start = "rcctl start unbound"
  w.stop = "rcctl stop unbound"
  w.restart = "rcctl restart unbound"
  w.start_grace = 10.seconds
  w.restart_grace = 15.seconds
  w.pid_file = "/var/run/unbound.pid"

  w.behavior(:clean_pid_file)

  w.start_if do |start|
    start.condition(:process_running) do |c|
      c.interval = 5.seconds
      c.running = false
    end
  end
end


