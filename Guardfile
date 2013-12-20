# A sample Guardfile
# More info at https://github.com/guard/guard#readme

#guard :shell do
#  watch /(.*)/ do |m|
#    n m[0], 'Changed'
#    `say -v cello #{m[0]}`
#  end
#end

guard :restarter, :command => "./cfbot-start.sh development" do
  watch(/.*/)
end
