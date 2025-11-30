guard :rspec, cmd: 'rspec', failed_mode: :keep,
      all_after_pass: true, all_on_start: true do

  watch(%r{^spec/.+_spec\.rb$})
#  watch(%r{^spec/requests/(.+)_spec}) { |m| [

  watch(%r{^config/routes.rb})

  watch(%r{^routes.rb})
  watch(%r{^app/.+.rb$})
  watch(%r{^app/channels/(.+)\.rb$}) { |m| "spec/channels/#{m[1]}_spec.rb" }
  watch(%r{^lib/.+.rb$})
  watch(%r{^.+.js$})

end
