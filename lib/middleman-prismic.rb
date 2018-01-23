require 'prismic'
require 'middleman-core'
require 'middleman-prismic/version'
require 'middleman-prismic/commands/prismic'

module MiddlemanPrismic
  class << self
    attr_reader :options
  end

  class Core < Middleman::Extension

    option :api_url, nil, 'The prismic api url'
    option :release, 'master', 'Content release'
    option(
      :link_resolver,
      ->(link) { byebug; "http://www.example.com/#{link.type.pluralize}/#{link.slug}" },
      'The link resolver'
    )
    option :custom_queries, {}, 'Custom queries'
    option :output_dir, 'data', 'Location where the data information is saved to. Defaults to Middleman Default'

    def initialize(app, options_hash={}, &block)
      super

      MiddlemanPrismic.instance_variable_set('@options', options)
    end

    helpers do
    end
  end

end

::Middleman::Extensions.register(:prismic, ::MiddlemanPrismic::Core)