require 'rubygems'
require 'dm-core'
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
            rsrc_hash = JSON.parse(response.body)
            # Typecast attributes, DM expects them properly cast
            resource.model.properties.each do |prop|
              value = rsrc_hash[prop.field.to_s]
              if !value.nil?
                rsrc_hash[prop.field.to_s] = prop.typecast(value)
              end
            end

            resource.id = rsrc_hash["id"]

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

        if ! query.is_a?(DataMapper::Query)
          resources = [query].flatten
        else
          resources = read_many(query)
        end

        resources.each do |resource|
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
        results = read_many(query)
        results[0,1]
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
        json_query = make_json_query(query)

        tblname = Extlib::Inflection.classify(query.model).pluralize
        path = "/#{tblname}/#{json_query}"

        response = @persevere.retrieve(path)

        if response.code == "200"
          results = JSON.parse(response.body)
          results.each do |rsrc_hash|
            # Typecast attributes, DM expects them properly cast
            query.model.properties.each do |prop|
              value = rsrc_hash[prop.field.to_s]
              if !value.nil?
                rsrc_hash[prop.field.to_s] = prop.typecast(value)
              end
            end
          end

          resources = query.model.load(results, query)
        else
          return false
        end

        query.filter_records(resources)
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

        if ! query.is_a?(DataMapper::Query)
          resources = [query].flatten
        else
          resources = read_many(query)
        end

        resources.each do |resource|
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

        if uri_or_options.class
          @identity_maps = {}
        end

        @options = Hash.new

        uri_or_options.each do |k,v|
          @options[k.to_sym] = v
        end

        @options[:scheme] = @options[:adapter]
        @options.delete(:scheme)

        uri = URI::HTTP.build(@options).to_s

        @persevere = Persevere.new(uri)
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

      def make_json_query(query)
        query_terms = Array.new

        conditions = query.conditions

        conditions.each do |condition|
          operator, property, bind_value = condition
          if ! property.nil? && !bind_value.nil?
            v = property.typecast(bind_value)
            if v.is_a?(String)
              value = "'#{bind_value}'"
            else
              value = "#{bind_value}"
            end

            query_terms << case operator
                           when :eql then "#{property.field()}=#{value}"
                           when :lt then  "#{property.field()}<#{value}"
                           when :gt then  "#{property.field()}>#{value}"
                           when :lte then "#{property.field()}<=#{value}"
                           when :gte then "#{property.field()}=>#{value}"
                           when :not then "#{property.field()}!=#{value}"
                           when :like then "#{property.field()}~'*#{value}*'"
                           else puts "Unknown condition: #{operator}"
                           end
          end
        end

        if query_terms.length != 0
          query = "?#{query_terms.join("&")}"
        else
          query = ""
        end

        query
      end
    end
  end
end
