# BioCatalogue: app/models/soap_output.rb
#
# Copyright (c) 2009-2010, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

class SoapOutput < ActiveRecord::Base
  if ENABLE_CACHE_MONEY
    is_cached :repository => $cache
    index :soap_operation_id
  end
  
  acts_as_annotatable :name_field => :name
  
  acts_as_archived
  
  belongs_to :soap_operation
  
  serialize :computational_type_details
  
  if ENABLE_SEARCH
    searchable do
      text :name, :computational_type, :computational_type_details_for_solr, :description
    end
  end
  
  if USE_EVENT_LOG
    acts_as_activity_logged(:models => { :referenced => { :model => :soap_operation } })
  end
  
  def to_json
    generate_json_and_make_inline(false)
  end 
  
  def to_inline_json
    generate_json_and_make_inline(true)
  end
    
  def preferred_description
    # Either the description from the service description doc, 
    # or the last description annotation.
    
    desc = self.description
    
    if desc.blank?
      desc = self.annotations_with_attribute("description", true).first.try(:value_content)
    end
    
    return desc
  end
  
  def associated_service_id
    @associated_service_id ||= BioCatalogue::Mapper.map_compound_id_to_associated_model_object_id(BioCatalogue::Mapper.compound_id_for(self.class.name, self.id), "Service")
  end
  
  def associated_service
    @associated_service ||= Service.find_by_id(associated_service_id)
  end
  
  def associated_soap_operation_id
    self.soap_operation_id
  end
  
  def associated_soap_operation
    @associated_soap_operation = SoapOperation.find_by_id(associated_soap_operation_id)
  end

protected
  
  def computational_type_details_for_solr
    BioCatalogue::Util.all_values_from_hash(self.computational_type_details).collect {|i| i.downcase}.uniq.to_sentence(:words_connector => ' ', :last_word_connector => ' ', :two_words_connector => ' ')
  end
  
private

  def generate_json_and_make_inline(make_inline)
    data = {
      "soap_output" => {
        "name" => self.name,
        "description" => self.preferred_description,
        "computational_type" => self.computational_type,
        "created_at" => self.created_at.iso8601,
        "archived_at" => self.archived? ? self.archived_at.iso8601 : nil
      }
    }

    unless make_inline
      data["soap_output"]["self"] = BioCatalogue::Api.uri_for_object(self)
			return data.to_json
    else
      data["soap_output"]["resource"] = BioCatalogue::Api.uri_for_object(self)
			return data["soap_output"].to_json
    end
  end # generate_json_and_make_inline


end
