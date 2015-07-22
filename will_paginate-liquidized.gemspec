require 'rake'

Gem::Specification.new do |s|
  s.name        = 'will_paginate-liquidized'
  s.summary     = "will_paginate-liquidized"
  s.authors     = ["Jim Gilliam", "David Huie"]
  s.version     = "1"
  s.files       = FileList["lib/**/*.rb"].to_a
  s.add_runtime_dependency "will_paginate"
  s.add_runtime_dependency "liquid"
end
