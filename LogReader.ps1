# powershell.exe -ExecutionPolicy Bypass -NoExit -File "C:\Path\To\LogViewer.ps1" shortcut for clickable application
# This script is a simple log viewer that allows users to load log files, filter by level and process, and view the logs in a grid format.
# It uses Windows Forms for the UI and DataGridView for displaying the logs.

# import assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Data


# ----- SPLASH SCREEN -----
$splash = New-Object Windows.Forms.Form
$splash.Text = "Launching Log Viewer Pro..."
$splash.FormBorderStyle = 'None'
$splash.StartPosition = 'CenterScreen'
$splash.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$splash.Size = New-Object Drawing.Size(400, 200)
$splash.TopMost = $true

# Label
$lblSplash = New-Object Windows.Forms.Label
$lblSplash.Text = "Log Viewer Pro"
$lblSplash.ForeColor = 'White'
$lblSplash.Font = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
$lblSplash.AutoSize = $true
$lblSplash.Location = New-Object Drawing.Point(100, 60)

# Sub Label
$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = "Loading, please wait..."
$lblSub.ForeColor = 'Gray'
$lblSub.Font = New-Object Drawing.Font("Segoe UI", 10)
$lblSub.AutoSize = $true
$lblSub.Location = New-Object Drawing.Point(125, 110)

# Add controls
$splash.Controls.Add($lblSplash)
$splash.Controls.Add($lblSub)


# # Decode Base64 into a stream
# $gifBytes = [System.Convert]::FromBase64String($gifBase64)
# $gifStream = New-Object System.IO.MemoryStream
# $gifStream.Write($gifBytes, 0, $gifBytes.Length)
# $gifStream.Position = 0
# # Load GIF into PictureBox
# $gifImage = [System.Drawing.Image]::FromStream($gifStream)

# Image path
$gifPath = ".\magnify_search.gif"

# Add animated PictureBox
$gifBox = New-Object Windows.Forms.PictureBox
$gifBox.ImagePath = $gifPath
$gifBox.SizeMode = 'StretchImage'
$gifBox.Size = New-Object Drawing.Size(100,100)
$gifBox.Location = New-Object Drawing.Point(5, 10)  # left center-ish

$splash.Controls.Add($gifBox)


# Optional: splash opacity fade-in/out
$splash.Opacity = 0
$splashTimer = New-Object Windows.Forms.Timer
$splashTimer.Interval = 50
$fadeStep = 0.05

$splashTimer.Add_Tick({
    if ($splash.Opacity -lt 1.0) {
        $splash.Opacity += $fadeStep
    } else {
        Start-Sleep -Milliseconds 1200  # Pause for effect
        $splashTimer.Stop()
        $splash.Close()
    }
})

# Show splash and fade it in
$splash.Add_Shown({ $splashTimer.Start() })
$splash.ShowDialog() | Out-Null



# start of main form


# ---- Form Setup ----
$form = New-Object System.Windows.Forms.Form
$form.Text = "Log Viewer Pro"
$form.Size = New-Object System.Drawing.Size(900,600)
$form.StartPosition = "CenterScreen"

# ---- Controls ----

# Load Button
$btnLoad = New-Object System.Windows.Forms.Button
$btnLoad.Text = "Load Log File"
$btnLoad.Size = New-Object System.Drawing.Size(120,30)
$btnLoad.Location = New-Object System.Drawing.Point(10,10)

# LEVEL Filter Dropdown
$comboLevel = New-Object System.Windows.Forms.ComboBox
$comboLevel.Location = New-Object System.Drawing.Point(150,10)
$comboLevel.Size = New-Object System.Drawing.Size(120,30)
$comboLevel.DropDownStyle = 'DropDownList'
$comboLevel.Items.AddRange(@("ALL", "INFO", "WARN", "ERROR", "DEBUG"))

# PROCESS Filter Dropdown
$comboProcess = New-Object System.Windows.Forms.ComboBox
$comboProcess.Location = New-Object System.Drawing.Point(280,10)
$comboProcess.Size = New-Object System.Drawing.Size(150,30)
$comboProcess.DropDownStyle = 'DropDownList'
$comboProcess.Items.Add("ALL") | Out-Null

# Filter Button
$btnFilter = New-Object System.Windows.Forms.Button
$btnFilter.Text = "Apply Filter"
$btnFilter.Size = New-Object System.Drawing.Size(100,30)
$btnFilter.Location = New-Object System.Drawing.Point(440,10)

# Start Date Picker
$startDatePicker = New-Object System.Windows.Forms.DateTimePicker
$startDatePicker.Location = New-Object System.Drawing.Point(550,10)
$startDatePicker.Size = New-Object System.Drawing.Size(120,30)
$startDatePicker.Format = 'Short'
$startDatePicker.Value = (Get-Date).AddDays(-1)

# End Date Picker
$endDatePicker = New-Object System.Windows.Forms.DateTimePicker
$endDatePicker.Location = New-Object System.Drawing.Point(680,10)
$endDatePicker.Size = New-Object System.Drawing.Size(120,30)
$endDatePicker.Format = 'Short'
$endDatePicker.Value = Get-Date


# DataGridView
$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(10,50)
$grid.Size = New-Object System.Drawing.Size(860,500)
$grid.AutoSizeColumnsMode = 'Fill'
$grid.ReadOnly = $true
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false

# Add color-coding event right here
$grid.add_RowPrePaint({
    param($sender, $e)

    $row = $grid.Rows[$e.RowIndex]
    $level = $row.Cells["LEVEL"].Value

    switch ($level) {
        "ERROR" { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Salmon }
        "WARN"  { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Khaki }
        "INFO"  { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen }
        "DEBUG" { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightBlue }
    }
})

# Globals
$global:FullTable = $null

# ---- FUNCTIONS ----

function Load-LogFile {
    $fileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $fileDialog.Filter = "Log Files (*.log;*.txt)|*.log;*.txt|All Files (*.*)|*.*"
    $fileDialog.Title = "Select a Log File"

    if ($fileDialog.ShowDialog() -eq 'OK') {
        $filePath = $fileDialog.FileName

        # Create DataTable
        $table = New-Object System.Data.DataTable
        $table.Columns.Add("DATETIME") | Out-Null
        $table.Columns.Add("PROCESS")  | Out-Null
        $table.Columns.Add("LEVEL")    | Out-Null
        $table.Columns.Add("MESSAGE")  | Out-Null

        foreach ($line in Get-Content -Path $filePath) {
            if ($line.Trim() -ne "") {
                $parts = $line -split "\|"
                if ($parts.Count -ge 4) {
                    $row = $table.NewRow()
                    $row["DATETIME"] = $parts[0].Trim()
                    $row["PROCESS"]  = $parts[1].Trim()
                    $row["LEVEL"]    = $parts[2].Trim()
                    $row["MESSAGE"]  = $parts[3].Trim()
                    $table.Rows.Add($row) | Out-Null
                }
            }
        }

        $global:FullTable = $table
        Populate-ProcessDropdown -Table $table
        Show-FilteredTable
    }
}

function Populate-ProcessDropdown {
    param($Table)

    $comboProcess.Items.Clear()
    $comboProcess.Items.Add("ALL")

    $uniqueProcesses = $Table | Select-Object -Expand PROCESS -Unique
    foreach ($proc in $uniqueProcesses) {
        $comboProcess.Items.Add($proc)
    }

    $comboProcess.SelectedIndex = 0
}

function Show-FilteredTable {
    $levelFilter = $comboLevel.SelectedItem
    $procFilter  = $comboProcess.SelectedItem
    $startDate = $startDatePicker.Value.Date
    $endDate = $endDatePicker.Value.Date.AddDays(1).AddSeconds(-1)

    $filter = @()

    if ($levelFilter -and $levelFilter -ne "ALL") {
        $filter += "LEVEL = '$levelFilter'"
    }
    if ($procFilter -and $procFilter -ne "ALL") {
        $filter += "PROCESS = '$procFilter'"
    }

    if($startDate -and $endDate) {
        $filter += "DATETIME >= '$($startDate.ToString("yyyy-MM-dd HH:mm:ss"))'"
        $filter += "DATETIME <= '$($endDate.ToString("yyyy-MM-dd HH:mm:ss"))'"
    }

    
    $view = New-Object System.Data.DataView $global:FullTable
    
    if ($filter.Count -gt 0) {
        $view.RowFilter = $filter -join " AND "
    }
    $view.Sort = "DATETIME DESC"
    
    $grid.DataSource = $view
    
    
    Color-Code-Grid
    
}

function Color-Code-Grid{
    try{
        if($grid){
            $grid.RowPrePaint.Add({
                param($sender, $e)

                $row = $grid.Rows[$e.RowIndex]
                $level = $row.Cells["LEVEL"].Value

                switch ($level) {
                    "ERROR" { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Salmon }
                    "WARN"  { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::Khaki }
                    "INFO"  { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightGreen }
                    "DEBUG" { $row.DefaultCellStyle.BackColor = [System.Drawing.Color]::LightBlue }
                }
            })
        }
    } catch{

    }
}



# ---- Hook Events ----
$btnLoad.Add_Click({ Load-LogFile }) | Out-Null
$btnFilter.Add_Click({ Show-FilteredTable }) | Out-Null


# ---- Add Controls ----
$form.Controls.Add($btnLoad) | Out-Null
$form.Controls.Add($comboLevel) | Out-Null
$form.Controls.Add($comboProcess) | Out-Null
$form.Controls.Add($btnFilter) | Out-Null
$form.Controls.Add($startDatePicker) | Out-Null
$form.Controls.Add($endDatePicker) | Out-Null

$form.Controls.Add($grid) | Out-Null

# ---- Show UI ----
$form.ShowDialog() | Out-Null
return $null