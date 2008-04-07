class BlankSlate #:nodoc:
  instance_methods.each { |m| undef_method m unless m =~ /^__/ || m =~ /class/ }
end