using System.Reflection.Emit;
using System.Reflection.Metadata;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Todo.Data.Entity.Configuration;

internal class ItemConfiguration : IEntityTypeConfiguration<Item>
{
    private const string TableName = "Item";
    public void Configure(EntityTypeBuilder<Item> builder)
    {
        builder
            .ToTable(TableName);

        builder.Property<int>(p => p.ID).HasColumnName("ID");

        builder.Property(p => p.ID).ValueGeneratedOnAdd();
    }
}