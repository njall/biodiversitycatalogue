# BioCatalogue: app/helpers/tags_helper.rb
#
# Copyright (c) 2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details

module TagsHelper
  def generate_tag_cloud(tags, *args)
    BioCatalogue::Tags.tag_cloud(tags, *args)
  end
end