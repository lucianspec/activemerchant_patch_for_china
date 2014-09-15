require File.dirname(__FILE__) + '/alipay_wap/notification.rb'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module AlipayWap
        def self.notification(post)
          Notification.new(post)
        end
      end
    end
  end
end
