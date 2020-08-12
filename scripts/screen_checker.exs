{:ok, pid} = ScreenChecker.start_link([])

IO.puts("Screen checker is now running")

ref = Process.monitor(pid)

# Wait on the supervisor process forever (or until it terminates for some reason)
receive do
  {:DOWN, ^ref, _, _} -> :exit
end
