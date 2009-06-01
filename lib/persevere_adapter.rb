gem 'dm-core', '~> 0.9.10'
require 'dm-core'
require 'rubygems'
require 'extlib'
require 'json'
require 'persevere'

module DataMapper
  module Adapters
    class PersevereAdapter < AbstractAdapter
      ##
      # Used by DataMapper to put records into a data-store: "INSERT"
      # in SQL-speak.  It takes an array of the resources (model
      # instances) to be saved. Resources each have a key that can be
      # used to quickly look them up later without searching, if the
      # adapter supports it.
      #
      # @param [Array<DataMapper::Resource>] resources
      #   The set of resources (model instances)
      #
      # @return [Integer]
      #   The number of records that were actually saved into the
      #   data-store
      #
      # @api semipublic
      def create(resources)
        created = 0
        resources.each do |resource|
          #
          # This isn't the best solution but for an adapter, it'd be nice
          # to support objects being in *tables* instead of in one big icky
          # sort of table.
          #
          tblname = Extlib::Inflection.classify(resource.class).pluralize

          if ! @classes.include?(tblname)
            payload = {
              'id' => tblname,
              'extends' => { "$ref" => "/Class/Object" }
            }

            response = @persevere.create("/Class/", payload)
          end

          path = "/#{tblname}/"
          payload = resource.attributes
          payload.delete(:id)

          response = @persevere.create(path, payload)

          # Check the response, this needs to be more robust and raise
          # exceptions when there's a problem

          if response.code == "201"# good:
            rh = JSON.parse(response.body)
            created += 1
          else
            return false
          end
        end

        # Return the number of resources created in persevere.
        return created
      end

      ##
      # Used by DataMapper to update the attributes on existing
      # records in a data-store: "UPDATE" in SQL-speak. It takes a
      # hash of the attributes to update with, as well as a query
      # object that specifies which resources should be updated.
      #
      # @param [Hash] attributes
      #   A set of key-value pairs of the attributes to update the
      #   resources with.
      # @param [DataMapper::Query] query
      #   The query that should be used to find the resource(s) to
      #   update.
      #
      # @return [Integer]
      #   the number of records that were successfully updated
      #
      # @api semipublic
      def update(attributes, query)
        updated = 0
        puts "In Update A: #{attributes} Q: #{query.conditions.inspect}"
        resources = read_many(query)
        puts "Resources found: #{resources}"
        resources.each do |resource|
          key = resource.class.key(self.name).map do |property|
            resource.instance_variable_get(property.instance_variable_name)
          end

          tblname = Extlib::Inflection.classify(resource.class).pluralize
          path = "/#{tblname}/#{resource.id}"

          result = @persevere.update(path, resource.attributes)

          if result # good:
            updated += 1
          else
            return false
          end
        end
        return updated
      end

      ##
      # Look up a single record from the data-store. "SELECT ... LIMIT
      # 1" in SQL.  Used by Model#get to find a record by its
      # identifier(s), and Model#first to find a single record by some
      # search query.
      #
      # @param [DataMapper::Query] query
      #   The query to be used to locate the resource.
      #
      # @return [DataMapper::Resource]
      #   A Resource object representing the record that was found, or
      #   nil for no matching records.
      #
      # @api semipublic

      def read_one(query)
        read_many(query)[0]
      end

      ##
      # Looks up a collection of records from the data-store: "SELECT"
      # in SQL.  Used by Model#all to search for a set of records;
      # that set is in a DataMapper::Collection object.
      #
      # @param [DataMapper::Query] query
      #   The query to be used to seach for the resources
      #
      # @return [DataMapper::Collection]
      #   A collection of all the resources found by the query.
      #
      # @api semipublic
      def read_many(query)
        resources = Array.new

        json_query = make_json_query(query.conditions)

        tblname = Extlib::Inflection.classify(query.model).pluralize
        path = "/#{tblname}/#{json_query}"

        response = @persevere.retrieve(path)

        if response.code == "200"
          results = JSON.parse(response.body)
          results.each do |result|
            values = query.fields.collect do |field|
              result[field.field.to_s]
            end
            resources << query.model.load(values, query)
          end
        else
          return false
        end

        # Return results
        resources
      end

      alias :read :read_many

      ##
      # Destroys all the records matching the given query. "DELETE" in SQL.
      #
      # @param [DataMapper::Query] query
      #   The query used to locate the resources to be deleted.
      #
      # @return [Integer]
      #   The number of records that were deleted.
      #
      # @api semipublic
      def delete(query)
        deleted = 0
        resources = read_many(query)
        resources.each do |resource|
          key = resource.class.key(self.name).map do |property|
            resource.instance_variable_get(property.instance_variable_name)
          end

          tblname = Extlib::Inflection.classify(resource.class).pluralize
          path = "/#{tblname}/#{resource.id}"

          result = @persevere.delete(path)

          if result # ok
            deleted += 1
          end
        end
        return deleted
      end

      private

      ##
      # Make a new instance of the adapter. The @model_records ivar is
      # the 'data-store' for this adapter. It is not shared amongst
      # multiple incarnations of this adapter, eg
      # DataMapper.setup(:default, :adapter => :in_memory);
      # DataMapper.setup(:alternate, :adapter => :in_memory) do not
      # share the data-store between them.
      #
      # @param [String, Symbol] name
      #   The name of the DataMapper::Repository using this adapter.
      # @param [String, Hash] uri_or_options
      #   The connection uri string, or a hash of options to set up
      #   the adapter
      #
      # @api semipublic

      def initialize(name, uri_or_options)
        super
        @persevere = Persevere.new(make_uri(uri_or_options))
        @resource_naming_convention = NamingConventions::Resource::Underscored
        @identity_maps = {}
        @classes = []

        # Because this is an AbstractAdapter and not a
        # DataObjectAdapter, we can't assume there are any schemas
        # present, so we retrieve the ones that exist and keep them up
        # to date
        result = @persevere.retrieve('/Class[=id]')
        if result.code == "200"
          hresult = JSON.parse(result.body)
          hresult.each do |cname|
            junk,name = cname.split("/")
            @classes << name
          end

        else
          puts "Error retrieving existing tables: ", result.message
        end
      end

      def make_uri(uri_or_options)
        if uri_or_options.is_a?(String)
          begin
            URI.parse(uri_or_options)
            return uri_or_options.to_s
          rescue URI::InvalidURIError => e
            puts "Error parsing persevere URI: ", e
          end
        elsif uri_or_options.is_a?(Hash)
          nh = uri_or_options.dup
          nh[:scheme] = nh[:adapter]
          nh.delete(:scheme)
          return URI::HTTP.build(nh).to_s
        end
      end

      ##
      # Convert a DataMapper Resource to a JSON.
      #
      # @param [Query] query
      #   The DataMapper query object passed in
      #
      # @api semipublic
      def make_json(resource)
        json_rsrc = nil

        # Gather up all the attributes
        json_rsrc = resource.attributes.to_json
      end

      ##
      # Convert a DataMapper Query to a JSON Query.
      #
      # @param [Query] query
      #   The DataMapper query object passed in
      #
      # @api semipublic

      def make_json_query(conditions)
        query_terms = Array.new
        conditions.each do |condition|
          v = condition[1].typecast(condition[2])
          if v.is_a?(String)
            value = "'#{condition[2]}'"
          else
            value = "#{condition[2]}"
          end
          case condition[0]
          when :eql
            query_terms << "#{condition[1].field()}=#{value}"
          when :lt
            query_terms << "#{condition[1].field()}<#{value}"
          when :gt
            query_terms << "#{condition[1].field()}>#{value}"
          when :lte
            query_terms << "#{condition[1].field()}<=#{value}"
          when :gte
            query_terms << "#{condition[1].field()}=>#{value}"
          when :not
            query_terms << "#{condition[1].field()}!=#{value}"
          when :like
            if condition[2].is_a?(String)
              query_terms << "#{condition[1].field()}~'*#{condition[2].to_s}*'"
            end
          else
            puts "Unknown condition: #{condition[0]}"
          end
        end
        query = "?#{query_terms.join("&")}"
      end
    end
  end
end
