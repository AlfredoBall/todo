using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations.Schema;
using System.Text;

namespace Todo.Data.Entity;

public class Item
{
    public int ID { get; set; }
    public required int ClipboardID { get; set; }
    public required string Name { get; set; }
    public bool IsComplete { get; set; } = false;
}