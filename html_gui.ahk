gui_generateTable(param_data, param_columns:="", param_style:="table-bordered table-striped")
{
	static nw := NeutronWindow

	if !param_columns
	{
		param_columns := []
		for _, object in param_data {
			for key, value in object {
				if (param_columns.indexOf(key) = -1) {
					param_columns.push(key)
				}
			}
		}
	}

	out := "<table class=""table " param_style " ""><thead class=""thead-dark"">"
	for _, title in param_columns
		out .= nw.FormatHTML("<td>{}</td>", title)
	out .= "</thead>"

	out .= "<tbody>"
	for y, row in param_data
	{
		out .= "<tr>"
		for _, title in param_columns {
			if (inStr(row[title], ".jpeg") || inStr(row[title], ".jpg")) {
				out .= nw.FormatHTML("<td><img src='{}' width='100'></td>", row[title])
				continue
			}
			if (title == "id") {
				out .= nw.FormatHTML("<td><a href='https://www.cargurus.com/Cars/spt_used_cars?sourceContext=cargurus#listing={}' target='_blank'>link</a></td>", row[title])
				continue
			}
			out .= nw.FormatHTML("<td>{}</td>", row[title])
		}
		out .= "</tr>"
	}
	out .= "</tbody></table>"

	return out
}