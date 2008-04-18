# Singleton used for comunicate controllers with models.
module MetaRails
  module MetaScaffold
    class Singleton
      cattr_accessor :current_profile
    end
  end
end
