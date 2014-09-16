require 'net/http'
require 'active_merchant/billing/integrations/alipay_wap/sign'
require 'digest/md5'
require 'cgi'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module AlipayWap
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include Sign

          def complete?
            %w(TRADE_SUCCESS TRADE_FINISHED).include?(trade_status)
          end
          
          def refund?
            false
          end

          def pending?
            trade_status == 'WAIT_BUYER_PAY'
          end

          def status
            trade_status
          end
       
          def success?
            params['result'] == 'success'
          end
          
          def acknowledge
            raise StandardError.new("Faulty alipay result: ILLEGAL_SIGN") unless verify_sign
            true
          end

          %w(
             total_fee 
             trade_status 
             trade_no 
             out_trade_no 
             notify_time 
             buyer_email
             notify_id
             refund_status
          ).each do |method|
             define_method method
               get_value(method)
             end
          end

          private

          def get_value(node)
            CGI.unescape(params[:notify_data]).to_s.gsub("\n",'').match(/#{node}\>(.*?)\<\/#{node}/).to_a[1]
          end
 
          def verify_sign
            sign_type = params.delete("sign_type")
            sign = params.delete("sign")
            alipay_key = ActiveMerchant::Billing::Integrations::Alipay::EMAIL_NEW
            
            md5_string = params.sort.collect do |s|
              s[0] + "=" + CGI.unescape(s[1])
            end
            Digest::MD5.hexdigest(md5_string.join("&") + alipay_key) == sign.downcase
          end

        end
      end
    end
  end
end
