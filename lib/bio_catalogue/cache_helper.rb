# BioCatalogue: lib/bio_catalogue/cache_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Helper module to provide functions to aid in caching.

module BioCatalogue
  module CacheHelper
    
    NO_VALUE = "<none>".freeze
    
    module Expires
      
      def expire_service_index_tag_cloud
        expire_fragment(:controller => 'services', :action => 'index', :action_suffix => 'tag_cloud')
      end
      
    end
    
  end
end