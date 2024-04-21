# puma.rb
threads_count = ENV.fetch("MAX_THREADS") { 1 }
threads threads_count, threads_count

port        ENV.fetch("PORT") { 9291 }
environment ENV.fetch("RACK_ENV") { 'development' }

plugin :tmp_restart
