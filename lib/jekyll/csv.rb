require 'jekyll/csv/version'

require 'open-uri'
require 'csv'

require 'jekyll'

module Jekyll
  module Csv
    class CollectionPopulator
      attr_reader :conf

      def initialize(conf)
        @conf = conf
      end

      def populate(site)
        collection = Collection.new(site, collection_name)
        csv_data.each do |item|
          # If the display flag is set and it doesn't start with "y", skip this item
          if display_flag and item[display_flag] and !item[display_flag].downcase().start_with?('y')
            next
          end
          path = File.join(site.source, "_#{collection_name}", "#{Jekyll::Utils.slugify(item[slug_field])}.md")
          doc = Document.new(path, collection: collection, site: site)
          doc.merge_data!(item)
          if site.layouts.key?(collection_name)
            doc.merge_data!({'layout' => collection_name})
            doc.merge_data!({'slug' => item[slug_field]})
            if title_field
              doc.merge_data!({'title' => item[title_field]})
            end
            if image_field
              doc.merge_data!({'image' => item[image_field]})
            end
            if description_field
              doc.merge_data!({'description' => item[description_field]})
            end
          end
          collection.docs << doc
        end
        site.collections[collection_name] = collection
      end

      def collection_name
        @collection_name ||= conf['collection_name']
      end

      def csv_data
        @csv_data ||= CSV.parse(csv_string, headers: true).map(&:to_hash)
      end

      def csv_string
        @csv_string ||= URI.open(conf['source']).read
      end

      def slug_field
        @slug_field ||= conf.fetch('slug', csv_data.first.keys.first)
      end
      
      def title_field
        @title_field ||= conf.fetch('title', nil)
      end

      def image_field
        @image_field ||= conf.fetch('image', nil)
      end
      
      def description_field
        @description_field ||= conf.fetch('description', nil)
      end

      def display_flag
        @display_flag ||= conf.fetch('display_flag', nil)
      end
    end

    class Generator < ::Jekyll::Generator
      priority :low

      def generate(site)
        return unless site.config['csv']
        site.config['csv'].each do |collection_name, conf|
          conf['collection_name'] = collection_name
          CollectionPopulator.new(conf).populate(site)
        end
      end
    end
  end
end
