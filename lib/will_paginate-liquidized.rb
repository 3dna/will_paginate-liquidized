require 'will_paginate/liquidized'
require 'will_paginate/liquidized/view_helpers'

# register the WillPaginate Liquid filter - fall through if class doesn't exist
Liquid::Template.register_filter(WillPaginate::Liquidized::ViewHelpers) rescue nil
