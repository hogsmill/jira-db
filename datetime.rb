def daysDifference(date1, date2)
  (Date.parse(date2) - Date.parse(date1)).to_i
end
