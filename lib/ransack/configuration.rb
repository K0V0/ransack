require 'ransack/constants'
require 'ransack/predicate'

module Ransack
  module Configuration

    mattr_accessor :predicates, :options
    self.predicates = {}
    self.options = {
      :search_key => :q,
      :ignore_unknown_conditions => true,
      :hide_sort_order_indicators => false,
      :hide_search_type_indicators => false,
      :generate_id_for_sortlink => true
    }

    def configure
      yield self
    end

    def add_predicate(name, opts = {})
      name = name.to_s
      opts[:name] = name
      compounds = opts.delete(:compounds)
      compounds = true if compounds.nil?
      compounds = false if opts[:wants_array]

      self.predicates[name] = Predicate.new(opts)

      Constants::SUFFIXES.each do |suffix|
        compound_name = name + suffix
        self.predicates[compound_name] = Predicate.new(
          opts.merge(
            :name => compound_name,
            :arel_predicate => arel_predicate_with_suffix(
              opts[:arel_predicate], suffix
              ),
            :compound => true
          )
        )
      end if compounds
    end

    # The default `search_key` name is `:q`. The default key may be overridden
    # in an initializer file like `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Name the search_key `:query` instead of the default `:q`
    #   config.search_key = :query
    # end
    #
    # Sometimes there are situations when the default search parameter name
    # cannot be used, for instance if there were two searches on one page.
    # Another name can be set using the `search_key` option with Ransack
    # `ransack`, `search` and `@search_form_for` methods in controllers & views.
    #
    # In the controller:
    # @search = Log.ransack(params[:log_search], search_key: :log_search)
    #
    # In the view:
    # <%= f.search_form_for @search, as: :log_search %>
    #
    def search_key=(name)
      self.options[:search_key] = name
    end

    # By default Ransack ignores errors if an unknown predicate, condition or
    # attribute is passed into a search. The default may be overridden in an
    # initializer file like `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Raise if an unknown predicate, condition or attribute is passed
    #   config.ignore_unknown_conditions = false
    # end
    #
    def ignore_unknown_conditions=(boolean)
      self.options[:ignore_unknown_conditions] = boolean
    end

    # By default, Ransack displays sort order indicator arrows in sort links.
    # The default may be globally overridden in an initializer file like
    # `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Hide sort link order indicators globally across the application
    #   config.hide_sort_order_indicators = true
    # end
    #
    def hide_sort_order_indicators=(boolean)
      self.options[:hide_sort_order_indicators] = boolean
    end

    # By default, if you don't specify names for label helpers inside form helper,
    # Ransack will try to get it from passed @search object, but will add additional
    # text describing type of search you are performing e.g.: "xxxx starts with" etc.
    # To disable this behavior and have only "xxxx" as label, 
    # modify `config/initializers/ransack.rb` as follows:
    #
    # Ransack.configure do |config|
    #   # Hide sort link order indicators globally across the application
    #   config.hide_search_type_indicators = true
    # end
    #

    def hide_search_type_indicators=(boolean)
       self.options[:hide_search_type_indicators] = boolean
    end

    # generate sortlink with ID element 
    # consisted of field name that are records sorted by with "_sort_link" suffix

    def generate_id_for_sortlink(boolean)
      self.options[:generate_id_for_sortlink] = boolean
    end

    def arel_predicate_with_suffix(arel_predicate, suffix)
      if arel_predicate === Proc
        proc { |v| "#{arel_predicate.call(v)}#{suffix}" }
      else
        "#{arel_predicate}#{suffix}"
      end
    end

  end
end
