# BioCatalogue: app/views/services/index.xml.builder
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

total_count = @services.total_entries
total_pages = @services.total_pages

# <?xml>
xml.instruct! :xml

# <services>
xml.tag! "services", 
         xlink_attributes(uri_for_collection("services", :params => params)), 
         xml_root_attributes do
  
  # <parameters>
  xml.parameters do
    
    # <page>
    xml.page @page
    
    # <filters>
    xml.filters do
      
      @current_filters.each do |filter_key, filter_ids|
        
        # <filterType>
        xml.filterType :name => BioCatalogue::Filtering.filter_type_to_display_name(filter_key), :urlKey => filter_key.to_s do
          
          filter_ids.each do |f_id|
            
            # <filter>
            xml.filter :urlValue => f_id,
                       :name => display_name_for_filter(filter_key, f_id)
            
          end
          
        end
        
      end
      
    end
    
    # <query>
    xml.query params[:q]
    
    # <sortBy>
    xml.sortBy @sortby
    
    # <sortOrder>
    xml.sortOrder @sortorder
  end
  
  # <statistics>
  xml.statistics do
    
    # <totalPages>
    xml.totalPages total_pages
    
    # <itemCounts>
    xml.itemCounts do 
      
      # <total>
      xml.total total_count      
      
    end
    
  end
  
  # <results>
  xml.results do
    
    # <service> *
    @services.each do |service|
      xml.service xlink_attributes(uri_for_object(service), :title => xlink_title(service)) do
        
        render :partial => "services/api/core_elements", :locals => { :parent_xml => xml, :service => service }
        
        # <summary>
        if @api_params[:include_elements].include?("summary")
          render :partial => "services/api/summary", :locals => { :parent_xml => xml, :service => service }
        end
        
        # <related>
        xml.related do
          
          # <summary>
          xml.summary xlink_attributes(uri_for_object(service, :sub_path => "summary"), :title => xlink_title("Summary view of Service - #{service.name}"))
          
        end
        
      end
    end
    
  end
  
  # <related>
  xml.related do
    
    params_clone = BioCatalogue::Util.duplicate_params(params)
    
    # <previous>
    unless @page == 1
      xml.previous previous_link_xml_attributes(uri_for_collection("services", :params => params_clone.merge(:page => (@page - 1))))
    end
    
    # <next>
    unless total_pages == 0 or total_pages == @page 
      xml.next next_link_xml_attributes(uri_for_collection("services", :params => params_clone.merge(:page => (@page + 1))))
    end
    
    # <filters>
    xml.filters xlink_attributes(uri_for_collection("services/filters", :params => params_clone.reject{|k,v| k.to_s.downcase == "page" }), 
                                 :title => xlink_title("Filters for the services index"))
    
    # <sorted> *
    
  end
  
end