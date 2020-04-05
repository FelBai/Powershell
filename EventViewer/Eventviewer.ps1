#Load Assembly and Library
Add-Type -AssemblyName PresentationFramework


#XAML form designed using Vistual Studio
[xml]$Form = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="Eventlogs" Height="1000" Width="1200" ResizeMode="CanResize">
    <Grid>
               <TabControl>
                    <TabItem Header="System Logs">
                        <Grid Background="#FFE5E5E5">
                            <DataGrid Name="SystemDataGrid" HorizontalAlignment="Left" Margin="10,60,0,0" VerticalAlignment="Top" SelectionMode="Single" />
                            <Button Name="ExportSystem" Content="Add to Exclude List" HorizontalAlignment="Left" Margin="10,20,0,0" VerticalAlignment="Top" Width="126" RenderTransformOrigin="2,1.227"/>
                            
                            <TextBox Name="KommentarBox" HorizontalAlignment="Left" Height="20" Margin="150,20,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="201" />
                            <Label Name="Kommentar" Content="Kommentar:" HorizontalAlignment="Left" Margin="150,0,0,0" VerticalAlignment="Top" Height="30" Width="110"/>
                           
                            <TextBox Name="ApprovedFromBox" HorizontalAlignment="Left" Height="20" Margin="240,20,0,0" TextWrapping="Wrap" VerticalAlignment="Top" Width="201" />
                            <Label Name="ApprovedFrom" Content="Approved From:" HorizontalAlignment="Left" Margin="240,0,0,0" VerticalAlignment="Top" Height="30" Width="110"/>
                       
                      </Grid>
                    </TabItem>
                    
                    <!--Application in progress -->
                    <TabItem Header="Application Logs">
                        <Grid Background="#FFE5E5E5">
                            <DataGrid Name="ApplicationDataGrid" HorizontalAlignment="Left" Margin="10,40,0,0" VerticalAlignment="Top" SelectionMode="Single" />
                            <Button Name="ExportApplication" Content="Add to Exclude List" HorizontalAlignment="Left" Margin="10,10,0,0" VerticalAlignment="Top" Width="126" RenderTransformOrigin="2,1.227" />
                        </Grid>
                    </TabItem>

               </TabControl>
       
    </Grid>
</Window>
"@



#Create a form
$XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
$XMLForm = [Windows.Markup.XamlReader]::Load($XMLReader)

#Load Controls
$SystemDataGrid = $XMLForm.FindName('SystemDataGrid')
$ApplicationDataGrid = $XMLForm.FindName('ApplicationDataGrid')
$ExportSystem = $XMLForm.FindName('ExportSystem')
$ExportApplication = $XMLForm.FindName('ExportApplication')
$KommentarBox = $XMLForm.FindName('KommentarBox')
$ApprovedFromBox = $XMLForm.FindName('ApprovedFromBox')

#Create array object for Result DataGrid
$SystemEventLogs = New-Object System.Collections.ArrayList
$ApplicationEventlogs = New-Object System.Collections.ArrayList

#Filter SystemLogs             
$ExcludeSystemEvents = ""
$ExcludeSystemEvents = Import-Csv .\ExcludedSystemLogs.csv 

$AarrayExcludeSystemEvents = @()
foreach ($Event in $ExcludeSystemEvents ) {
    $PSpObject = New-Object psobject -Property @{
        Eventid = $event.eventid 
    }
    $AarrayExcludeSystemEvents += $PSpObject
}

#Filter ApplicationLogs             
$ExcludeApplicationEvents = ""
$ExcludeApplicationEvents = Import-Csv .\ExcludedApplicationLogs.csv 

$AarrayExcludeApplicationEvents = @()
foreach ($Event in $ExcludeApplicationEvents) {
    $PSpObject = New-Object psobject -Property @{
        Eventid = $event.eventid 
    }
    $AarrayExcludeApplicationEvents += $PSpObject
}


#Get SystemEventlogs
$SystemEventLogs = Get-EventLog -LogName system -EntryType Error -After (Get-Date).AddDays(-7) | where eventid -NotIn $AarrayExcludeSystemEvents.eventid | select TimeGenerated, Entrytype, Source, EventID,Message |Sort-Object -Property TimeGenerated


#Get Applicationslogs
$ApplicationEventlogs = Get-EventLog -LogName application -EntryType Error -After (Get-Date).AddDays(-7) | where eventid -NotIn $AarrayExcludeApplicationEvents.eventid | select TimeGenerated, Entrytype, Source, EventID,Message |Sort-Object -Property TimeGenerated


#Build Datagrid 
$SystemDataGrid.ItemsSource = @($SystemEventLogs)
$ApplicationDataGrid.ItemsSource = @($ApplicationEventlogs)


#Button ExportSystem Action
$ExportSystem.add_click( {
        if ( ($ApprovedFromBox.text -eq '') -or ($KommentarBox.text -eq '') ) {
            [System.Windows.MessageBox]::Show("Kommentar: und Approved From: Eintragen")
        }


        else {
            $SelectedRow = $SystemDataGrid.SelectedItem
                        
            if ( $SelectedRow -eq $null) {
                [System.Windows.MessageBox]::Show("Kein Event ausgewählt")
            }

            else {
                $ExportCsv = $SelectedRow
                $ExportCsv | Add-Member -NotePropertyName Kommentar -NotePropertyValue $KommentarBox.text
                $ExportCsv | Add-Member -NotePropertyName ApprovedFrom -NotePropertyValue $ApprovedFromBox.text
                $ExportCsv | Export-Csv .\ExcludedSystemLogs.csv  -NoTypeInformation -Append
            
            }
        }
    })

#Button ExportSystem Action
$ExportApplication.add_click( {
        
        $known = $ApplicationDataGrid.SelectedItem
        $known | Add-Member -NotePropertyName Kommentar -NotePropertyValue $KommentarBox.text
        $known | Export-Csv .\ExcludedApplicationLogs.csv -NoTypeInformation -Append
        
    })


#Show XMLform
$XMLForm.ShowDialog()


