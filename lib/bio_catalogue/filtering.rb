# BioCatalogue: lib/bio_catalogue/filtering.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

# Module to carry out the bulk of the logic for filtering, filtering,
# advanced search, and so on.

module BioCatalogue
  module Filtering
    
    # ====================
    # Filtering URL format
    # --------------------

    # Filters are specified via the query parameters in URLs.
    # The general format for this is:
    #   ...?filter_type_1=[value1],[value2],[value3]&filter_type_2=[value4]&filter_type_3=[value5],[value6]&...

    # ====================
    
    UNKNOWN_TEXT = "(unknown)".freeze
    
    FILTER_KEYS = [ :cat, :t, :p, :su, :sr, :tag, :tag_s, :tag_ops, :tag_ins, :tag_outs, :c ].freeze
    
    TAG_FILTER_KEYS = [ :tag, :tag_s, :tag_ops, :tag_ins, :tag_outs ].freeze
    
    def self.filter_type_to_display_name(filter_type)
      case filter_type
        when :cat
          "Service Categories"
        when :t
          "Service Types"
        when :p
          "Service Providers"
        when :su
          "Submitters (Users)"
        when :sr
          "Submitters (Registries)"
        when :tag
          "Tags"
        when :tag_s
          "Tags (on Services)"
        when :tag_ops
          "Tags (on Operations)"
        when :tag_ins
          "Tags (on Inputs)"
        when :tag_outs
          "Tags (on Outputs)"
        when :c
          "Countries"
        else
          "(unknown)"
      end
    end
    
    # ======================
    # Filter options finders
    # ----------------------
    
    # TODO: potentially for the future...
    # Gets an alphabetically sorted list of the categories, as a tree.
    # Example return data:
    # [ { "name" => "x", "count" => "5", "children" => [ [ { "name" => "xx", "count" => "4" }, { "name" => "xy", "count" => "11" }, ... ] ] }, { "name" => "y", "count" => "11", "children" => [ ] }, ... ]
    #def self.get_filters_for_categories
    #  [ { "name" => "x", "count" => "5", "children" => [ [ { "name" => "xx", "count" => "4" }, { "name" => "xy", "count" => "11" } ] ] }, { "name" => "y", "count" => "11", "children" => [ ] } ]
    #end
    
    # Gets an ordered list of all the service providers and their counts of services.
    # Example return data:
    # [ { "name" => "ebi.ac.uk", "count" => "12" }, { "name" => "example.com", "count" => "11" }, ... ]
    def self.get_filters_for_service_providers(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT service_providers.name AS name, COUNT(*) AS count 
            FROM service_providers 
            INNER JOIN service_deployments ON service_providers.id = service_deployments.service_provider_id 
            INNER JOIN services ON services.id = service_deployments.service_id 
            GROUP BY service_providers.id 
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
    # Gets an ordered list of all the different service types and their counts of services.
    # Example return data:
    # [ { "name" => "SOAP", "count" => "102" }, { "name" => "REST", "count" => "11" }, ... ]
    def self.get_filters_for_service_types(limit=nil)
      filters = { }
      
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT service_versions.service_versionified_type AS name, COUNT(*) AS count 
            FROM service_versions 
            INNER JOIN services ON services.id = service_versions.service_id 
            GROUP BY service_versions.service_versionified_type 
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      filters = ActiveRecord::Base.connection.select_all(sql)
      
      # Need to "massage" the returned data...
      
      filters.each do |f|
        f["name"] = f["name"].constantize.new.service_type_name
      end
      
      return filters
    end
    
    # Gets an ordered list of all the submitters that are Users and their counts of services.
    # Example return data:
    # [ { "name" => "John", "count" => "181" }, { "name" => "Paula", "count" => "11" }  ... ]
    def self.get_filters_for_submitters_users(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT users.display_name AS name, COUNT(*) AS count 
            FROM users 
            INNER JOIN services ON services.submitter_type = 'User' AND services.submitter_id = users.id 
            GROUP BY users.id
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
    # Gets an ordered list of all the submitters that are Registries and their counts of services.
    # Example return data:
    # [ { "name" => "Feta", "count" => "181" }, { "name" => "Seekda", "count" => "11" }  ... ]
    def self.get_filters_for_submitters_registries(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT registries.display_name AS name, COUNT(*) AS count 
            FROM registries 
            INNER JOIN services ON services.submitter_type = 'Registry' AND services.submitter_id = registries.id 
            GROUP BY registries.id
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      return ActiveRecord::Base.connection.select_all(sql)
    end
    
    # Gets an ordered list of all the countries (the service deployments are in) and their counts of services.
    # Example return data:
    # [ { "name" => "England", "count" => "18" }, { "name" => "Germany", "count" => "5" }, { "name" => "(unknown)", "count" => "3" }  ... ]
    def self.get_filters_for_countries(limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = "SELECT service_deployments.country AS name, COUNT(*) AS count 
            FROM service_deployments 
            INNER JOIN services ON services.id = service_deployments.service_id 
            GROUP BY service_deployments.country
            ORDER BY COUNT(*) DESC"
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql += " LIMIT #{limit}"
      end
       
      items = ActiveRecord::Base.connection.select_all(sql)
      
      # IGNORE: Need to replace the blank name with "(unknown)" (for services that don't have a country set)...
      # ... no easy way to get this to work right now so delete the empty value for now...
      items.each do |item|
        if item['name'].blank?
          item['name'] = UNKNOWN_TEXT
        end
      end
      
      return items
    end
    
    # Gets an ordered list of all the tags on Services, ServiceVersions, 
    # ServiceDeployments and any root service type Models (eg: SoapService).
    # Example return data:
    # [ { "name" => "blast", "count" => "500" }, { "name" => "bio", "count" => "110" }  ... ]
    def self.get_filters_for_service_tags(limit=nil)
      service_models = [ "Service", "ServiceVersion", "ServiceDeployment" ] + Mapper::SERVICE_TYPE_ROOT_MODELS.map{|m| m.to_s}
      get_filters_for_tags_by_service_models(service_models, limit)
    end
    
    # Gets an ordered list of all the tags on SoapOperations.
    # Example return data:
    # [ { "name" => "blast", "count" => "500" }, { "name" => "bio", "count" => "110" }  ... ]
    def self.get_filters_for_soap_operation_tags(limit=nil)
      get_filters_for_tags_by_service_models([ "SoapOperation" ], limit)
    end
    
    # Gets an ordered list of all the tags on SoapInputs.
    # Example return data:
    # [ { "name" => "blast", "count" => "500" }, { "name" => "bio", "count" => "110" }  ... ]
    def self.get_filters_for_soap_input_tags(limit=nil)
      get_filters_for_tags_by_service_models([ "SoapInput" ], limit)
    end
    
    # Gets an ordered list of all the tags on SoapOutputs.
    # Example return data:
    # [ { "name" => "blast", "count" => "500" }, { "name" => "bio", "count" => "110" }  ... ]
    def self.get_filters_for_soap_output_tags(limit=nil)
      get_filters_for_tags_by_service_models([ "SoapOutput" ], limit)
    end
    
    # ======================
    
    # Returns back a cloned params object with the new filter specified within it.
    def self.add_filter_to_params(params, filter_type, filter_value)
      params_dup = BioCatalogue::Util.duplicate_params(params)
    
      if params_dup[filter_type].blank?
        params_dup[filter_type] = "[#{filter_value}]"
      else
        params_dup[filter_type] << ",[#{filter_value}]"
      end
      
      # Reset page param
      params_dup.delete(:page)
      
      return params_dup
    end
    
    # Returns back a cloned params object with the filter specified removed from it.
    def self.remove_filter_from_params(params, filter_type, filter_value)
      params_dup = BioCatalogue::Util.duplicate_params(params)
    
      unless params_dup[filter_type].blank?
        params_dup[filter_type].gsub!("[#{filter_value}],", "")
        params_dup[filter_type].gsub!(",[#{filter_value}]", "")
        params_dup[filter_type].gsub!("[#{filter_value}]", "")
      end
      
      params_dup.delete(filter_type) if params_dup[filter_type].blank?
      
      # Reset page param
      params_dup.delete(:page)
      
      return params_dup
    end
    
    def self.is_filter_selected(current_filters, filter_type, filter_value)
      return current_filters[filter_type] && current_filters[filter_type].include?(filter_value.to_s)
    end
    
    # Returns:
    #   [ conditions, joins ] for use in an ActiveRecord .find method (or .paginate).
    def self.generate_conditions_and_joins_from_filters(filters, search_query=nil)
      conditions = { }
      joins = [ ]
      
      # Replace the unknown filter with nil
      filters.each do |k,v|
        v.each do |f|
          if f == UNKNOWN_TEXT
            v << nil
            v.delete(f)
          end
        end
      end
            
      # Now build the conditions and joins...
      
      service_ids_categories = [ ]
      service_ids_submitters = [ ]
      service_ids_tags_s = [ ]
      service_ids_tags_ops = [ ]
      service_ids_tags_ins = [ ]
      service_ids_tags_outs = [ ]
      service_ids_search_query = [ ]
      
      unless filters.blank?
        filters.each do |filter_type, filter_values|
          unless filter_values.blank?
            case filter_type
              when :cat
                service_ids_categories = get_service_ids_with_categories(filter_values)
              when :t
                service_types = [ ]
                filter_values.each do |f|
                  # TODO: strip this out into a more generic mapping table (prob in config or lib)
                  case f.downcase
                    when 'soap'
                      service_types << 'SoapService'
                    when 'rest'
                      service_types << 'RestService'
                  end
                end
                
                unless service_types.blank?
                  conditions[:service_versions] = { :service_versionified_type => service_types }
                  joins << :service_versions
                end
              when :p
                providers = filter_values
                
                unless providers.blank?
                  conditions[:service_deployments] = { } if conditions[:service_deployments].blank?
                  conditions[:service_deployments][:service_providers] = { :name => providers }
                  joins << [ { :service_deployments => :provider } ]
                end
              when :c
                countries = filter_values
                
                unless countries.blank?
                  conditions[:service_deployments] = { } if conditions[:service_deployments].blank?
                  conditions[:service_deployments][:country] = countries
                  joins << [ :service_deployments ]
                end
              when :su
                service_ids_submitters.concat(get_service_ids_with_submitter_users(filter_values))
              when :sr
                service_ids_submitters.concat(get_service_ids_with_submitter_registries(filter_values))
              when :tag_s
                service_models = [ "Service", "ServiceVersion", "ServiceDeployment" ] + Mapper::SERVICE_TYPE_ROOT_MODELS.map{|m| m.to_s}
                service_ids_tags_s = get_service_ids_with_tag_on_service_models(service_models, filter_values)
              when :tag_ops
                service_ids_tags_ops = get_service_ids_with_tag_on_service_models([ "SoapOperation" ], filter_values)
              when :tag_ins
                service_ids_tags_ins = get_service_ids_with_tag_on_service_models([ "SoapInput" ], filter_values)
              when :tag_outs
                service_ids_tags_outs = get_service_ids_with_tag_on_service_models([ "SoapOutput" ], filter_values)
            end
          end
        end
      end
      
      # Take into account search query if present
      unless search_query.blank?
        search_query = Search.preprocess_query(search_query)
        search_results = Search.search(search_query, "services")
        service_ids_search_query = search_results.all_item_ids("services")
      end
      
      # Need to go through the various service IDs found for the different criterion 
      # and add to the conditions collection (if common ones are found).
      # This ANDs the service IDs (ie: uses only the service IDs that match all criterion).
      
      # To carry out this process properly, we set a dummy value of 0 to any array that returned NO service IDs.
      service_ids_categories = [ 0 ] if service_ids_categories.empty? and filters.has_key?(:cat)
      service_ids_submitters = [ 0 ] if service_ids_submitters.empty? and (filters.has_key?(:su) or filters.has_key?(:sr))
      service_ids_tags_ops = [ 0 ] if service_ids_tags_s.empty? and filters.has_key?(:tag_s)
      service_ids_tags_ops = [ 0 ] if service_ids_tags_ops.empty? and filters.has_key?(:tag_ops)
      service_ids_tags_ins = [ 0 ] if service_ids_tags_ins.empty? and filters.has_key?(:tag_ins)
      service_ids_tags_outs = [ 0 ] if service_ids_tags_outs.empty? and filters.has_key?(:tag_outs)
      service_ids_search_query = [ 0 ] if service_ids_search_query.empty? and !search_query.blank?
      
      Util.say "*** service_ids_categories = #{service_ids_categories.inspect}"
      Util.say "*** service_ids_submitters = #{service_ids_submitters.inspect}"
      Util.say "*** service_ids_tags_s = #{service_ids_tags_s.inspect}"
      Util.say "*** service_ids_tags_ops = #{service_ids_tags_ops.inspect}"
      Util.say "*** service_ids_tags_ins = #{service_ids_tags_ins.inspect}"
      Util.say "*** service_ids_tags_outs = #{service_ids_tags_outs.inspect}"
      Util.say "*** service_ids_search_query = #{service_ids_tags_outs.inspect}"
      
      service_id_arrays_to_process = [ ]
      service_id_arrays_to_process << service_ids_categories unless service_ids_categories.blank?
      service_id_arrays_to_process << service_ids_submitters unless service_ids_submitters.blank?
      service_id_arrays_to_process << service_ids_tags_s unless service_ids_tags_s.blank?
      service_id_arrays_to_process << service_ids_tags_ops unless service_ids_tags_ops.blank?
      service_id_arrays_to_process << service_ids_tags_ins unless service_ids_tags_ins.blank?
      service_id_arrays_to_process << service_ids_tags_outs unless service_ids_tags_outs.blank?
      service_id_arrays_to_process << service_ids_search_query unless service_ids_search_query.blank?
 
      final_service_ids = nil
      
      service_id_arrays_to_process.each do |a|
        if final_service_ids.nil?
          final_service_ids = a
        else
          final_service_ids = (final_service_ids & a)
        end
      end
      
      Util.say "*** final_service_ids (after combining service id arrays) = #{final_service_ids.inspect}"
      
      unless final_service_ids.nil?
        # Remove the dummy value of 0 in case it is in there
        final_service_ids.delete(0)
        
        # If a filter that relies on service IDs was specified but no services were found then no services should be returned
        final_service_ids = [ -1 ] if final_service_ids.blank? and 
                                      (filters.has_key?(:cat) or
                                       filters.has_key?(:su) or 
                                       filters.has_key?(:sr) or 
                                       filters.has_key?(:tag_s) or
                                       filters.has_key?(:tag_ops) or 
                                       filters.has_key?(:tag_ins) or 
                                       filters.has_key?(:tag_outs) or 
                                       !search_query.blank?)
        
        Util.say "*** final_service_ids (after cleanup) = #{final_service_ids.inspect}"
        
        conditions[:id] = final_service_ids unless final_service_ids.blank?
      end
      
      return [ conditions, joins ]
    end
    
    # Converts the params from a URL query string into a more structured filters collection.
    # Example return value:
    #   { :t => [ "SOAP" ], :p => [ "ebi.ac.uk", "ddbj.jp" ], :c => [ "USA", "(unknown)" ] }
    #
    # Note: irrelevant query parameters will be ignored and left untouched.
    def self.convert_params_to_filters(params)
      filters = { }
      
      params.each do |key, values|
        key_sym = key.to_s.to_sym
        filters[key_sym] = self.split_filter_options_string(values) if FILTER_KEYS.include?(key_sym)
      end
      
      Rails.logger.info "*** convert_params_to_filters returned #{filters.inspect}"
      
      return filters
    end
    
    # Remember the query format (mentioned above):
    # ...?filter_type_1=[value1],[value2],[value3]&filter_type_2=[value4]&filter_type_3=[value5],[value6]&...
    #
    # This method splits one set of values for one filter_type into an array of values.
    # ie: splits the string "[value1],[value2],[value3],...,[valuen]"
    def self.split_filter_options_string(filter_options)
      filter_options_splitted = filter_options.split("],[")
      
      # Now the first item will have a '[' at the beginning, and the last item will have a ']'...
      # NOTE: array[-1] refers to the last item in the Array.
      
      filter_options_splitted[0] = filter_options_splitted[0][1..-1]
      filter_options_splitted[-1] = filter_options_splitted[-1][0...-1] 
      
      return filter_options_splitted
    end
    
    # Converts a list of values (or one value) into a string that can be used as the value for a query parameter.
    def self.values_to_query_parameter_text(values)
      return "" if values.blank?
      
      text = ""
      
      values = [ values ].flatten
      
      values.each do |v|
        if text.blank?
          text = "[#{v}]"
        else
          text << ",[#{v}]"
        end
      end
      
      return text
    end
    
    protected
    
    # Gets an ordered list of all the tags on a particular set of models.
    # The counts that are returned reflect the number of services that match 
    # (taking into account mapping of service substructure objects to the parent service).
    # 
    # Example return data:
    # [ { "name" => "blast", "count" => "500" }, { "name" => "bio", "count" => "110" }  ... ]
    def self.get_filters_for_tags_by_service_models(model_names, limit=nil)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = [ "SELECT annotations.value AS name, annotations.annotatable_id AS id, annotations.annotatable_type AS type
              FROM annotations 
              INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
              WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?)",
              model_names ]
      
      # If limit has been provided in the URL then add that to query.
      if !limit.nil? && limit.is_a?(Fixnum) && limit > 0
        sql[0] = sql[0] + " LIMIT #{limit}"
      end
      
      items = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
      
      # Group these tags and find out how many services match.
      # NOTE: MUST take into account that multiple service substructure objects could belong to the same Service, AND
      # take into account tags with different case (must treat them in a case-insensitive way).
      
      grouped_tags = { }
      
      items.each do |item|
        found = false
        
        tag_name = item['name']
        
        grouped_tags.each do |k,v|
          if k.downcase == tag_name.downcase
            found = true
            grouped_tags[k] << "#{item['type']}:#{item['id']}"
          end
        end
        
        unless found
          grouped_tags[tag_name] = [ ] if grouped_tags[tag_name].nil?
          grouped_tags[tag_name] << "#{item['type']}:#{item['id']}"
        end
          
      end
      
      filters = [ ]
      
      grouped_tags.each do |tag_name, op_ids|
        service_ids = BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(op_ids, "Service")
        service_ids.uniq!
        filters << { 'name' => tag_name, 'count' => service_ids.length.to_s }
      end
      
      filters.sort! { |a,b| b['count'].to_i <=> a['count'].to_i }
      
      return filters
    end
    
    def self.get_service_ids_with_categories(categories)
      results = [ ]
      
      categories.map{|c| c.to_i}.each do |c_id|
        results.concat(Categorising.get_service_ids_with_category(c_id))
      end
      
      return results
    end
    
    def self.get_service_ids_with_submitter_users(user_display_names)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = [ "SELECT services.id
              FROM services 
              INNER JOIN users ON services.submitter_type = 'User' AND services.submitter_id = users.id 
              WHERE users.display_name IN (?)",
              user_display_names ]
      
      results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
      
      return results.map{|r| r['id'].to_i}.uniq
    end
    
    def self.get_service_ids_with_submitter_registries(registry_display_names)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = [ "SELECT services.id
              FROM services 
              INNER JOIN registries ON services.submitter_type = 'Registry' AND services.submitter_id = registries.id 
              WHERE registries.display_name IN (?)",
              registry_display_names ]
      
      results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
      
      return results.map{|r| r['id'].to_i}.uniq
    end
    
    def self.get_service_ids_with_tag_on_service_models(model_names, tag_values)
      # NOTE: this query has only been tested to work with MySQL 5.0.x
      sql = [ "SELECT annotations.annotatable_id AS id, annotations.annotatable_type AS type
              FROM annotations 
              INNER JOIN annotation_attributes ON annotations.attribute_id = annotation_attributes.id
              WHERE annotation_attributes.name = 'tag' AND annotations.annotatable_type IN (?) AND annotations.value IN (?)",
              model_names,
              tag_values ]
      
      results = ActiveRecord::Base.connection.select_all(ActiveRecord::Base.send(:sanitize_sql, sql))
      
      return BioCatalogue::Mapper.process_compound_ids_to_associated_model_object_ids(results.map{|r| "#{r['type']}:#{r['id']}" }, "Service").uniq     
    end
   
  end
end