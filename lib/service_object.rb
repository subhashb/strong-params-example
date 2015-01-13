class ServiceUndefinedError < StandardError
  def initialize(klass)
    super("You must define a #{klass.class.name}#call method")
  end
end

class ServiceCallInvalidError < StandardError
  attr_reader :object

  def initialize(object)
    @object = object
    super("Service #{object.class.name} failed: #{object.errors.full_messages.join(', ')}")
  end
end

class ServiceExecutionError < StandardError
  attr_reader :object

  def initialize(object)
    @object = object
    super("Service #{object.class.name} failed: #{object.errors.full_messages.join(', ')}")
  end
end

module ServiceObject
  extend ActiveSupport::Concern

  included do
    include ActiveAttr::Model

    attr_reader :result
  end

  module ClassMethods
    def call(*args)
      new(*args).send(:proxy_call)
    end

    def needs(*services)
      services.each do |service|
        define_method service, lambda { |*args|
          s = service.to_s.camelize.constantize.new(*args)
          s.instance_variable_set(:@nested, true)
          result = s.send(:proxy_call)
          instance_variable_get(:@performed).push(s)
          result
        }
      end
    end
  end

  def initialize
    super
    @performed = []
    @nested = false
  end

  def call
    raise ServiceUndefinedError.new(self)
  end

  def failure?
    @failed || false
  end

  def success?
    !failure?
  end

  private

  def fail!(error = nil)
    @failed = true
    if error.is_a? ActiveModel::Errors
      error.each { |k,v| self.errors.add(k, v) }
    else
      errors.add :base, error if error
    end

  end

  def proxy_call
    raise ServiceCallInvalidError.new(self) if invalid?
    @result = self.call
    raise ServiceExecutionError.new(self) if failure?

    @success = true
    self

  rescue ServiceExecutionError => e

    rollback_performed
    raise e if @nested

    fail!(e.object.errors) unless e.object == self

    self
  end

  def rollback_performed
    @performed.reverse_each do |service| 
      Rails.logger.warn("Rolling back #{service.class.name}")
      service.rollback if service.respond_to?(:rollback)
    end
  end

end
