using System;
using System.Collections.Generic;
using System.Text;

namespace Todo.Data.Access;

public record Item(int ID, string Name, int ClipboardId, bool IsComplete = false);