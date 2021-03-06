require 'net/http'
require 'digest/md5'
require 'cgi'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module AlipayWap
        class Notification < ActiveMerchant::Billing::Integrations::Notification

          def complete?
            %w(TRADE_SUCCESS TRADE_FINISHED).include?(trade_status) || success?
          end
          
          def refund?
            false
          end

          def from_mobile?
            true
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
             define_method method do
               get_value(method)
             end
          end

          private

          def get_value(node)
            params[node] || CGI.unescape(params["notify_data"].to_s).gsub("\n",'').match(/#{node}\>(.*?)\<\/#{node}/).to_a[1]
          end
 
          def verify_sign
            sign_type = params.delete("sign_type")
            sign = params.delete("sign")
            alipay_key = ActiveMerchant::Billing::Integrations::Alipay::KEY_NEW
            
            if sign_type
              md5_string = params.sort.collect {|s| s[0] + "=" + CGI.unescape(s[1]) }.join("&")
            else
              md5_string = %w(service v sec_id notify_data).inject({}) {|h, key| h[key] = params[key]; h}.map{|k, v| "#{k}=#{v}"}.join("&")
            end
            Digest::MD5.hexdigest(md5_string + alipay_key) == sign.downcase
          end

        end
      end
    end
  end
end
