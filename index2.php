<?php
  set_time_limit(0);
  // system('net use Q: \\\\10.165.96.12\SWB /user:CXIVNXNAS02\user_rd Rec0rd@1ns /persistent:no');
  define("BASE_URL","https://rsv01.oncall.vn:8887/api/");
  define("RECORDINGS_URL",BASE_URL."recordings");
  define("BASE_DIR","\\\\10.165.96.12\\SWB\\PBX-Records\\");
  define("CSV_FILE","D:\\Haolc\\Devops\\shell-scripts\\input.csv");
  define("CERTIFICATE_FILE","D:\\Haolc\\Devops\\shell-scripts\\certificate.pem");
  
  //Call API function
  function callAPI($url,$method,$dataToSend,$token='',$isReturned=true,$isVerbose=true)
  {
    $headerData = [   'Content-Type: application/json',
                      'Host: rsv01.oncall.vn'
                  ];
    if($token != '' || $token != NULL)  
    { 
      $headerData [] = 'Authorization: Bearer '.$token; 
    }
    $curlOptionsArr =  [  CURLOPT_RETURNTRANSFER  => $isReturned,
                          CURLOPT_SSL_VERIFYPEER  => true,
                          CURLOPT_CAINFO          => CERTIFICATE_FILE,
                          CURLOPT_VERBOSE         => $isVerbose,
                          CURLOPT_URL             => $url,
                          CURLOPT_HTTPHEADER      => $headerData
                      ];
    if (in_array($method,['GET','POST','PUT','PUSH','DELETE','REPLACE']))
    {
      $curlOptionsArr [ CURLOPT_CUSTOMREQUEST ] = $method ;
    }
    if ($dataToSend != '' || $dataToSend != NULL)
    {
      $curlOptionsArr [ CURLOPT_POSTFIELDS ] = $dataToSend;
    }
    $curl = curl_init($url);
    curl_setopt_array($curl,$curlOptionsArr);
    $curl = curl_exec($curl);
    if ($isReturned === true)
    {
      return $curl;
    }
  }

  function createFolderFromCSVFile($csvFile,$date="")
  {
    if (($handle = fopen($csvFile, 'r')) !== false) 
    {
      while (($data = fgetcsv($handle, 1000, ",")) !== false) 
      {
        foreach ($data as $key => $value) 
        {
          if ($key == 1)
          {
            createFolder(BASE_DIR,"{$data[0]}_{$data[1]}");
          }
          if ($key > 2)
          {
            createFolder(BASE_DIR."{$data[0]}_{$data[1]}\\",$value);
            createFolder(BASE_DIR."{$data[0]}_{$data[1]}\\{$value}\\",$date);
          }
        }
      }
      fclose($handle);
      return 0;
    }
  }

  function getParentFolderFromCSV($csvFile,$string="")
  {
    if (($handle = fopen($csvFile, 'r')) !== false) 
    {
      while (($row = fgetcsv($handle)) !== false) 
      {
        if (in_array($string,$row))
        {
          return "{$row[0]}_{$row[1]}";
        }
      }
      fclose($handle);
      return 0;
    }
  }

  function createFolder($path,$folderName)
  {
    if (!file_exists($path.$folderName))
    { 
      mkdir ($path.$folderName);
    }
  }

  //Generate filename function
  function filenameGenerate($caller,$callee,$namePart)
  {
      $filename = '';
      if ($caller >= '1001' && $caller <= '1040')
      {
          $filename = 'OUTBOUND_from_'.$caller.'_to_'.$callee.'_'.$namePart[4];
          if ($callee == "*57") {
            $filename = 'OUTBOUND_from_'.$caller.'_to_VOICEMAIL_'.$namePart[4];
          }
      }
      else
      {
          $filename = 'INBOUND_from_'.$caller.'_to_'.$namePart[2].'_'.$namePart[4];
      }
      return $filename;
  }

  //Generate today string
  function today()
  {
    date_default_timezone_set('Asia/Ho_Chi_Minh');
    return date('Y-m-d', time());
  }

  //Get a token from Oncall API
  function getTokenFromOncall()
  {
    $url = BASE_URL.'tokens';
    $dataToSend = json_encode ([
      "username"  => "SGCX01177",
      "password"  => "cathay@2024",
      "domain"    => "sgcx01177.oncall"
    ]);
    $token = callAPI($url,'POST',$dataToSend,'',true,false);
    $token = json_decode($token,true);
    return $token['access_token'];
  }

  //Get all record from Oncall API
  function getAllRecords($token)
  {
    $url = RECORDINGS_URL;
    $recordFileList = callAPI($url,'GET','',$token,true,false);
    return json_decode($recordFileList,true);
  }

  //Get today record from Oncall API
  function getTodayRecords($token)
  {
    $url = RECORDINGS_URL."?filter=".urlencode("started_at gt '".today()."T00:00:00Z' and started_at lt '".today()."T23:59:59Z'");
    $todayRecordFileList = callAPI($url,'GET','',$token,true,false);
    return json_decode($todayRecordFileList,true);
  }

  //Get a file record info from Oncall API
  function getRecordFileInfo($id,$token)
  {
      $url = 'https://rsv01.oncall.vn:8887/api/recordings/'.$id;
      $fileInfo = callAPI($url,'GET','',$token,true,false);
      return json_decode($fileInfo,true);
  }

  function autoMove()
  {
    // Under construct
  }

  function writeToLog()
  {

  }

  //Main download function
  function downloadRecord($scope='all',$path)
  {
    createFolderFromCSVFile(CSV_FILE);
    $token = getTokenFromOncall();
    // Default is get all records
    $recordsList = getAllRecords($token);
    // If the scope is today, it will get a today records
    if ($scope == 'today') 
    {  
      $recordsList = getTodayRecords($token);
    }

    if (!empty($recordsList))
    {
      unset($recordsList['count']);
      foreach ($recordsList['items'] as $key => $item) 
      {
        $file = getRecordFileInfo($item['id'],$token);
        $file = array_filter($file['items'][0],function($item){
          return ($item);
        });
        $date = explode('T',$file['started_at']);
        $namePart = array_values(array_filter(explode('_',$file['filename'])));
        $caller = $file['caller'];
        $callee = $file['callee'];
        $parentFolder = getParentFolderFromCSV(CSV_FILE,$namePart[2]);
        $childFolder = $namePart[2];
        if ($parentFolder != 0)
        {
          $saveToPath = BASE_DIR."$parentFolder\\$childFolder\\";
          createFolder($saveToPath,$date[0]);
          $recordFileUrl = "https://rsv01.oncall.vn:8887/api/files/{$file['file_id']}/data";
          $filename = filenameGenerate($caller,$callee,$namePart);
          $saveToPath .= $date[0];
          $saveToPath = $saveToPath."\\".$filename;
          $WAVContent = callAPI($recordFileUrl,'GET','','',true,true);
          $fopen = fopen($saveToPath,'w');
          fwrite($fopen,$WAVContent);
          fclose($fopen);
          sleep(2);
        }
        // echo $saveToPath. "\n";
      }
    }
  }   
  downloadRecord("today",BASE_DIR);
?>