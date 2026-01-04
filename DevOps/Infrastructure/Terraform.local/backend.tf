terraform { 
  cloud { 
    
    organization = "amiasea" 

    workspaces { 
      name = "todo-local" 
    } 
  } 
}