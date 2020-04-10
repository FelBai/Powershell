#Load Assembly and Library
Add-Type -AssemblyName PresentationFramework


#XAML form designed using Vistual Studio
[xml]$Form = Get-Content .\window.xaml



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
$SystemEventLogs = Get-EventLog -LogName system -EntryType Error, warning -After (Get-Date).AddDays(-7) | 
where eventid -NotIn $AarrayExcludeSystemEvents.eventid | 
select TimeGenerated, Entrytype, Source, EventID, Message |
Sort-Object -Property TimeGenerated 


#Get Applicationslogs
$ApplicationEventlogs = Get-EventLog -LogName application -EntryType Error, warning -After (Get-Date).AddDays(-7) | 
where eventid -NotIn $AarrayExcludeApplicationEvents.eventid | 
select TimeGenerated, Entrytype, Source, EventID, Message |
Sort-Object -Property TimeGenerated


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


