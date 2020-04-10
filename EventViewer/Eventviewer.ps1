#Load Assembly and Library
Add-Type -AssemblyName PresentationFramework


#XAML form designed using Vistual Studio
[xml]$Form = Get-Content .\window.xaml



#Create a form
$XMLReader = (New-Object System.Xml.XmlNodeReader $Form)
$XMLForm = [Windows.Markup.XamlReader]::Load($XMLReader)

#Load Controls
$SystemDataGrid = $XMLForm.FindName('SystemDataGrid')
$ExportSystem = $XMLForm.FindName('ExportSystem')
$KommentarBox = $XMLForm.FindName('KommentarBox')
$ApprovedFromBox = $XMLForm.FindName('ApprovedFromBox')
$ShowSystemFilter = $XMLForm.FindName('ShowSystemFilter')



#Create array object for Result DataGrid
$SystemEventLogs = New-Object System.Collections.ArrayList


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



#Get SystemEventlogs
$SystemEventLogs = Get-EventLog -LogName system -EntryType Error, warning -After (Get-Date).AddDays(-7) | 
where eventid -NotIn $AarrayExcludeSystemEvents.eventid | 
select TimeGenerated, Entrytype, Source, EventID, Message |
Sort-Object -Property TimeGenerated 


#Build Datagrid 
$SystemDataGrid.ItemsSource = @($SystemEventLogs)


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
    $AarrayExcludeSystemEvents.count

$ShowSystemFilter.add_click({
    if ( $ExcludeSystemEvents.count -eq 0 ) {
        [System.Windows.MessageBox]::Show("Filter is Empty")
    }

    else {
        $ExcludeSystemEvents  | Out-GridView
    }
})



#Show XMLform
$XMLForm.ShowDialog()


