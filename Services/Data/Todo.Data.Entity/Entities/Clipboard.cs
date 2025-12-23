using System;
using System.Collections.Generic;
using System.Text;

namespace Todo.Data.Entity;

public class Clipboard
{
    public int ID { get; set; }
    public required string Name { get; set; }
    public List<Item> Items { get; set; } = new List<Item>();
    public Guid UserID { get; set; }
}
