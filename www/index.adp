<master>
<property name="title">Batch Importer</property>
<property name="context">context</property>
<property name="main_navbar_label">Admin</property>


<h1>Batch Importer</h1>

<table>
<tr>
	<td>package id</th>
	<td><%= $package_id %></td>
</tr>
<tr>
	<td>last run</th>
	<td><%= $last_run %></td>
</tr>
<%= $parameters %>
</table>

<h2>Last Imports</h2>

<listtemplate name="file_list"></listtemplate>
