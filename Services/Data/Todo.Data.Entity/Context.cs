using System;
using System.Net.NetworkInformation;
using Microsoft.EntityFrameworkCore;
using Todo.Data.Entity.Configuration;

namespace Todo.Data.Entity;

public class Context : DbContext
{
    public Context() : base() { }

    public Context(DbContextOptions<Context> options)
    : base(options)
    {
    }

    public DbSet<Clipboard> Clipboards { get; set; }

    public DbSet<Item> Items { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfiguration(new ClipboardConfiguration());
        modelBuilder.ApplyConfiguration(new ItemConfiguration());

        modelBuilder.Entity<Clipboard>().HasData(
            new Clipboard { ID = 1, Name = "Clipboard 1", UserID = new Guid("52515368-4ad4-4bae-9319-6886c234ee5a") },
            new Clipboard { ID = 2, Name = "Clipboard 2", UserID = new Guid("52515368-4ad4-4bae-9319-6886c234ee5a") },
            new Clipboard { ID = 3, Name = "Clipboard 3", UserID = new Guid("52515368-4ad4-4bae-9319-6886c234ee5a") }
        );

        modelBuilder.Entity<Item>().HasData(
            new Item { ID = 1, Name = "Item 1", ClipboardID = 1, IsComplete = true },
            new Item { ID = 2, Name = "Item 2", ClipboardID = 1, IsComplete = false },
            new Item { ID = 3, Name = "Item 3", ClipboardID = 2, IsComplete = true },
            new Item { ID = 4, Name = "Item 4", ClipboardID = 2, IsComplete = false },
            new Item { ID = 5, Name = "Item 5", ClipboardID = 3, IsComplete = true },
            new Item { ID = 6, Name = "Item 6", ClipboardID = 1, IsComplete = false },
            new Item { ID = 7, Name = "Item 7", ClipboardID = 1, IsComplete = true },
            new Item { ID = 8, Name = "Item 8", ClipboardID = 2, IsComplete = false },
            new Item { ID = 9, Name = "Item 9", ClipboardID = 2, IsComplete = true },
            new Item { ID = 10, Name = "Item 10", ClipboardID = 3, IsComplete = false },
            new Item { ID = 11, Name = "Item 11", ClipboardID = 3, IsComplete = true },
            new Item { ID = 12, Name = "Item 12", ClipboardID = 1, IsComplete = false },
            new Item { ID = 13, Name = "Item 13", ClipboardID = 1, IsComplete = true },
            new Item { ID = 14, Name = "Item 14", ClipboardID = 2, IsComplete = false },
            new Item { ID = 15, Name = "Item 15", ClipboardID = 2, IsComplete = true },
            new Item { ID = 16, Name = "Item 16", ClipboardID = 3, IsComplete = false },
            new Item { ID = 17, Name = "Item 17", ClipboardID = 3, IsComplete = true },
            new Item { ID = 18, Name = "Item 18", ClipboardID = 1, IsComplete = false },
            new Item { ID = 19, Name = "Item 19", ClipboardID = 1, IsComplete = true },
            new Item { ID = 20, Name = "Item 20", ClipboardID = 2, IsComplete = false },
            new Item { ID = 21, Name = "Item 21", ClipboardID = 2, IsComplete = true },
            new Item { ID = 22, Name = "Item 22", ClipboardID = 3, IsComplete = false },
            new Item { ID = 23, Name = "Item 23", ClipboardID = 3, IsComplete = true },
            new Item { ID = 24, Name = "Item 24", ClipboardID = 1, IsComplete = false },
            new Item { ID = 25, Name = "Item 25", ClipboardID = 1, IsComplete = true },
            new Item { ID = 26, Name = "Item 26", ClipboardID = 2, IsComplete = false },
            new Item { ID = 27, Name = "Item 27", ClipboardID = 2, IsComplete = true },
            new Item { ID = 28, Name = "Item 28", ClipboardID = 3, IsComplete = false },
            new Item { ID = 29, Name = "Item 29", ClipboardID = 3, IsComplete = true },
            new Item { ID = 30, Name = "Item 30", ClipboardID = 1, IsComplete = false },
            new Item { ID = 31, Name = "Item 31", ClipboardID = 1, IsComplete = true },
            new Item { ID = 32, Name = "Item 32", ClipboardID = 2, IsComplete = false },
            new Item { ID = 33, Name = "Item 33", ClipboardID = 2, IsComplete = true },
            new Item { ID = 34, Name = "Item 34", ClipboardID = 3, IsComplete = false },
            new Item { ID = 35, Name = "Item 35", ClipboardID = 3, IsComplete = true },
            new Item { ID = 36, Name = "Item 36", ClipboardID = 1, IsComplete = false },
            new Item { ID = 37, Name = "Item 37", ClipboardID = 1, IsComplete = true },
            new Item { ID = 38, Name = "Item 38", ClipboardID = 1, IsComplete = false },
            new Item { ID = 39, Name = "Item 39", ClipboardID = 1, IsComplete = true },
            new Item { ID = 40, Name = "Item 40", ClipboardID = 1, IsComplete = false },
            new Item { ID = 41, Name = "Item 41", ClipboardID = 1, IsComplete = true },
            new Item { ID = 42, Name = "Item 42", ClipboardID = 1, IsComplete = false },
            new Item { ID = 43, Name = "Item 43", ClipboardID = 1, IsComplete = true },
            new Item { ID = 44, Name = "Item 44", ClipboardID = 1, IsComplete = false },
            new Item { ID = 45, Name = "Item 45", ClipboardID = 1, IsComplete = true },
            new Item { ID = 46, Name = "Item 46", ClipboardID = 1, IsComplete = false },
            new Item { ID = 47, Name = "Item 47", ClipboardID = 1, IsComplete = true },
            new Item { ID = 48, Name = "Item 48", ClipboardID = 1, IsComplete = false },
            new Item { ID = 49, Name = "Item 49", ClipboardID = 1, IsComplete = true },
            new Item { ID = 50, Name = "Item 50", ClipboardID = 1, IsComplete = false }
        );
    }
}