using System;
using System.Collections.Generic;
using System.Text;

namespace Todo.Data.Access;

public record Clipboard(int ID, string Name, List<Item> items, Guid userID);