require 'jekyll/remote_csv/version'

require 'open-uri'
require 'csv'

require 'jekyll'

module Jekyll
  module RemoteCsv
    class Generator < ::Jekyll::Generator
      priority :low

      def generate(site)
        return unless site.config['remote_csv']
        site.config['remote_csv'].each do |source_name, conf|
          csv_string = open(conf['source']).read
          csv_data = CSV.parse(csv_string, headers: true).map(&:to_hash)
          site.data[source_name] = csv_data
          site.collections[source_name] = make_collection(site, source_name, conf, csv_data)
          next unless conf['collections']
          conf['collections'].each do |collection_name, key|
            next unless site.collections.key?(collection_name)
            key ||= 'id'
            csv_id_field = conf.fetch('csv_id_field', 'id')
            site.collections[collection_name].docs.each do |doc|
              doc.data[source_name] = site.collections[source_name].docs.find_all do |item|
                item[csv_id_field] == doc[key]
              end
              doc.data[source_name].each do |source_doc|
                source_doc.data[collection_name] ||= []
                source_doc.data[collection_name] << doc
              end
            end
          end
        end
      end

      def make_collection(site, source_name, conf, csv_data)
        collection = Collection.new(site, source_name)
        csv_data.each do |item|
          item_id_field = conf.fetch('item_id_field', item.keys.first)
          path = File.join(site.source, "_#{source_name}", "#{Jekyll::Utils.slugify(item[item_id_field])}.md")
          doc = Document.new(path, collection: collection, site: site)
          doc.merge_data!(item)
          if site.layouts.key?(source_name)
            doc.merge_data!('layout' => source_name)
          end
          collection.docs << doc
        end
        collection
      end
    end
  end
end
