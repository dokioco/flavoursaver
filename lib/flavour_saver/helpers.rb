require 'delegate'
require 'ostruct'

module FlavourSaver
  module Helpers
    class Defaults
      def with(args)
        yield.contents args
      end

      def each(collection)
        return unless collection.respond_to?(:each)

        r = []
        count = 0
        collection.each do |element|
          r << yield.contents(element, 'index' => count)
          count += 1
        end
        yield.rendered!
        r.join ''
      end

      def if(truthy)
        truthy = false if truthy.respond_to?(:size) && (truthy.size == 0)
        if truthy
          yield.contents
        else
          yield.inverse
        end
      end

      def unless(falsy,&b)
        falsy = false if falsy.respond_to?(:size) && (falsy.size == 0)
        self.if(!falsy,&b)
      end

      def this
        @source || self
      end

      def log(message)
        FlavourSaver.logger.debug("FlavourSaver: #{message}")
        ''
      end
    end

    class Decorator < Defaults

      def initialize(locals, source)
        @source = source
        mixin = Module.new do
          locals.each do |name,impl|
            define_method name, &impl
          end
        end
        extend(mixin)
      end

      def array?
        !!@source.is_a?(Array)
      end

      def [](accessor)
        if array?
          if accessor.match /[0-9]+/
            return @source.at(accessor.to_i)
          end
        end
        @source[accessor]
      end

      def respond_to?(name)
        super || @source.respond_to?(name)
      end

      def method_missing(name,*args,&b)
        # I would rather have it raise a NameError, but Moustache
        # compatibility requires that missing helpers return
        # nothing. A good place for bugs to hide.
        @source.public_send(name, *args, &b) if @source.respond_to? name
      end
    end

    module_function

    def registered_helpers
      @registered_helpers ||= {}
    end

    def register_helper(method,&b)
      if method.respond_to? :name
        registered_helpers[method.name.to_sym] = method
      elsif b
        registered_helpers[method.to_sym] = b
      end
    end

    def deregister_helper(*names)
      names.each do |name|
        registered_helpers.delete(name.to_sym)
      end
    end

    def reset_helpers
      @registered_helpers = {}
    end

    def decorate_with(context, helper_names=[], locals={})
      helpers = if helper_names.any?
                  helper_names = helper_names.map(&:to_sym)
                  registered_helpers.select { |k,v| helper_names.member? k }.merge(locals)
                else
                  helpers = registered_helpers
                end
      helpers = helpers.merge(locals)

      # Tilt wants OpenStructs, but we commonly use hashes
      # This will ensure that all hashes are converted at the time of use,
      # so that even nested hashes behave as they did with handlebars.rb
      if context.is_a? Hash
        context = OpenStruct.new context
      end

      Decorator.new(helpers, context)
    end

  end
end
