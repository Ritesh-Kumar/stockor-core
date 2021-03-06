module Skr
    module Concerns

        module INV

            module Lines

                def from_pick_ticket!
                    proxy_association.owner.pick_ticket.lines.each do | line |
                        build({ pt_line: line, qty: line.qty_to_ship })
                    end
                end

                def from_sales_order!
                    proxy_association.owner.sales_order.lines.each do | line |
                        build({ so_line: line, qty: line.qty_allocated })
                    end
                end

            end

        end
    end
end
