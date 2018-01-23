require 'yaml'
require 'fileutils'

module Middleman
  module Cli

    class Prismic < Thor
      check_unknown_options!

      namespace :prismic
      desc 'prismic', 'Import data from Prismic'

      def self.source_root
        ENV['MM_ROOT']
      end

      # Tell Thor to exit with a nonzero exit code on failure
      def self.exit_on_failure?
        true
      end

      def prismic
        data_dir = MiddlemanPrismic.options.data_dir
        reference = MiddlemanPrismic.options.release

        Dir.mkdir(data_dir) unless File.exists?(data_dir)

        FileUtils.rm_rf(Dir.glob("#{data_dir}/prismic_*"))

        api = ::Prismic.api(MiddlemanPrismic.options.api_url)
        response = api.form('everything').submit(api.ref(reference))

        available_documents = []
        response.each { |d| available_documents << d.type }

        available_documents.uniq!

        available_documents.each do |document_type|
          documents = response.select{|d| d.type == document_type}
          documents.each do |document|
            unique_page_name = document.fragments['unique_page_name'].value.parameterize.underscore
            if File.exists?("#{data_dir}/prismic_#{unique_page_name}.yml")
              raise "ERROR: yml file already exists for document slug #{document.slug}"
            else
              File.open("#{data_dir}/prismic_#{unique_page_name}.yml", 'w') do |f|
                hash = {}
                document.fragments.each do |section_name, content|
                  begin
                    hash[section_name] = {}
                    # investigate as_html further!
                    begin
                      hash[section_name]['html'] = content.as_html(nil)
                    rescue
                      puts "Unable to convert #{content.class} to html"
                    end
                    begin
                      hash[section_name]['text'] = content.as_text(nil)
                    rescue
                      puts "Unable to convert #{content.class} to text"
                    end
                  end
                end
                hash['s3_bucket_name'] = document.fragments['s3_bucket_name'].value
                hash['template_name'] = document.fragments['template_name'].value
                hash['page_id'] = document.id
                hash['page_name'] = unique_page_name
                f.write(hash.to_yaml)
              end
            end
          end
        end

        # MiddlemanPrismic.options.custom_queries.each do |k, v|
        #   response = api.form('everything').query(*v).submit(api.master_ref)
        #   File.open("data/prismic_custom_#{k}.yml", 'w') do |f|
        #     f.write(Hash[[*response.map.with_index]].invert.to_yaml)
        #   end
        # end
        puts 'DONE!'
      end
    end
    Base.register(Middleman::Cli::Prismic, 'prismic', 'prismic [options]', 'Import data from Prismic')
  end
end
