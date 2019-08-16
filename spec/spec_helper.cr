require "spec"
require "../src/dotenv"


Spec.before_each do
  ENV.delete("VAR")
  ENV.delete("VAR1")
  ENV.delete("VAR2")
  ENV.delete("VAR2")
  ENV.delete("HELLO")
end